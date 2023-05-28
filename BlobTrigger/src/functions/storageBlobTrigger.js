const { app } = require("@azure/functions");

//TODO: for large blobs, convert to '''dataType: "stream"''' trigger option if/when this feature becomes available
//      similar to what is being used in C#
app.storageBlob("storageBlobTrigger", {
  path: "whatever/{name}",
  connection: "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING",
  handler: async (blob, context) => {
    context.log(`app.storageBlob()->handler(): Storage blob function starts processing "${context.triggerMetadata.name}" blob (I)`);

    if (typeof blob === "undefined" || blob === null) throw Error("Received an invalid Blob as a parameter");

    context.log(`app.storageBlob()->handler(): Storage blob function starts processing "${context.triggerMetadata.name}" blob of the type "${blob.constructor.name}" with size ${blob.length} bytes`);

    await moveBlobToFilesShare(blob, context.triggerMetadata.name, context);

    context.log(`app.storageBlob()->handler(): Storage blob function finished processing "${context.triggerMetadata.name}" blob (III)`);
  },
});

//
async function moveBlobToFilesShare(blob, fullFileName, context) {
  // https://learn.microsoft.com/en-us/samples/azure/azure-sdk-for-js/storage-file-share-javascript/
  // https://learn.microsoft.com/en-us/azure/developer/javascript/sdk/authentication/azure-hosted-apps?tabs=azure-portal%2Cazure-app-service
  // https://learn.microsoft.com/en-us/javascript/api/overview/azure/storage-file-share-readme?view=azure-node-latest

  const fileName = fullFileName.replace(/^.*[\\\/]/, "");

  const AzureStorageFileShare = require("@azure/storage-file-share");
  const { ShareServiceClient } = require("@azure/storage-file-share");

  const connectionString = process.env.DESTINATION_STORAGE_ACCOUNT_CONNECTION_STRING;
  if (typeof connectionString === "undefined" || connectionString === null || connectionString === "") throw Error("Parameter 'DESTINATION_STORAGE_ACCOUNT_CONNECTION_STRING' is not configured");
  
  //atmo, Azure Storage File Share Library only supports SharedKey and Shared access signatures
  //https://learn.microsoft.com/en-us/javascript/api/overview/azure/storage-file-share-readme?view=azure-node-latest#authenticate-the-client
  //this should be investigated instead for managed identities: https://learn.microsoft.com/en-us/azure/storage/files/authorize-oauth-rest?tabs=portal
  const shareServiceClient = ShareServiceClient.fromConnectionString(connectionString);
  context.log(`app.storageBlob()->handler()->moveBlobToFilesShare(): Initialized shareServiceClient`);

  //await displayAvailableShares(context, shareServiceClient);

  //Init fileshare client
  const destinationFileShareName = process.env.DESTINATION_FILE_SHARE_NAME;
  if (!destinationFileShareName) throw Error("Parameter 'DESTINATION_FILE_SHARE_NAME' is not configured");
  const destinationShareClient = shareServiceClient.getShareClient(destinationFileShareName);
  context.log(`app.storageBlob()->handler()->moveBlobToFilesShare(): Initialized destinationShareClient`);
  
  //Create a new directory for each file upload
  const destinationDirectoryName = `upload${new Date().getTime()}`;
  const destinationDirectoryClient = destinationShareClient.getDirectoryClient(destinationDirectoryName);
  await destinationDirectoryClient.createIfNotExists();
  context.log(`app.storageBlob()->handler()->moveBlobToFilesShare(): Created destination directory "${destinationDirectoryClient.name}" successfully.`);

  //Create a file and save the blob into it
  const destinationFileClient = destinationDirectoryClient.getFileClient(fileName);
  await destinationFileClient.create(blob.length); //Blob... is not a blob, this blob is a Buffer - do not use blob.size;
  context.log(`app.storageBlob()->handler()->moveBlobToFilesShare(): Created the file "${destinationFileClient.name}" successfully to "${destinationDirectoryClient.name}".`);

  await destinationFileClient.uploadData(blob); 
  //TODO: delete Blob
  context.log(`app.storageBlob()->handler()->moveBlobToFilesShare(): Uploaded the file "${fileName}" successfully to "${destinationDirectoryClient.name}".`);
}

// async function displayAvailableShares(context, shareServiceClient) {
//   context.log("Visible shares:");
//   let shareIter = shareServiceClient.listShares();
//   let i = 1;
//   for await (const share of shareIter) {
//     context.log(`Share${i}: ${share.name}`);
//     i++;
//   }
//   context.log("Finished listing all shares");
// }
