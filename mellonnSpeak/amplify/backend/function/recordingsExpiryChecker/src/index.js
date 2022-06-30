require('es6-promise').polyfill();
require('isomorphic-fetch');
const AWSAppSyncClient = require('aws-appsync').default;
const AWS = require('aws-sdk');
const gql = require('graphql-tag');

let client;
const deleteRecording = gql`
mutation DeleteRecording($id: ID!, $_version: Int) {
  deleteRecording(input: {id: $id, _version: $_version}) {
    id
    _version
  }
}
`;
const queryRecording = gql`
query GetRecording($id: ID!) {
  getRecording(id: $id) {
    _version
  }
}
`;

var AWSS3 = require('aws-sdk/clients/s3');
var s3 = new AWSS3();
const fileTypes = ['waw', 'flac', 'm4p', 'm4a', 'm4b', 'mmf', 'aac', 'mp3', 'mp4', 'MP4'];
const maxKeys = 1000;
const expireTime = 180;

exports.handler = async (event) => {
  const params = {
    Bucket: process.env.STORAGE_MELLONNSPEAKS3EU_BUCKETNAME,
    MaxKeys: maxKeys,
    Prefix: "private/",
  };
  let result;
  
  try {
    result = await s3.listObjectsV2(params).promise();
    console.log(result);
    const content = result.Contents;
    await checkList(content);
    
    if (result.KeyCount == maxKeys) {
      let lastKey = content[content.length - 1].Key;
      let isFull = true;
      
      while (isFull) {
        try {
          const params2 = {
            Bucket: process.env.STORAGE_MELLONNSPEAKS3EU_BUCKETNAME,
            MaxKeys: maxKeys,
            Prefix: "private/",
            StartAfter: lastKey,
          };
          const res = await s3.listObjectsV2(params2).promise();
          const cont = res.Contents;
          await checkList(cont);
          
          if (res.KeyCount == maxKeys) {
            isFull = true;
            lastKey = cont[cont.length - 1].Key;
          } else {
            isFull = false;
          }
        } catch (err) {
          console.log('Error: ' + err);
        }
      }
    }
  } catch (err) {
    console.log('Something went wrong: ' + err);
  }
  
  const response = {
      statusCode: 200,
      body: JSON.stringify('Hello'),
  };
  return response;
};

async function checkList(list) {
  for (let file of list) {
    if (fileTypes.includes(file.Key.split('.')[1])) {
      const lastModified = new Date(file.LastModified);
      var expiryDate = new Date(file.LastModified);
      expiryDate = expiryDate.setDate(lastModified.getDate() + expireTime);
      let isExpired = expiryDate <= new Date().getTime();
      if (isExpired) {
        const splitKey = file.Key.split('/');
        const id = splitKey[splitKey.length - 1].split('.')[0];
        await removeRecording(id, splitKey[1], file.Key);
      }
    }
  }
}

async function removeRecording(id, userFolder, key) {
  console.log('Removing recording with id: ' + id);
  
  await removeVersions(id, userFolder);
  await removeFromDataStore(id);
  try {
    let deleteParams = {
      Bucket: process.env.STORAGE_MELLONNSPEAKS3EU_BUCKETNAME,
      Key: key,
    };
    await s3.deleteObject(deleteParams).promise();
    deleteParams.Key = 'public/finishedJobs/' + id + '.json';
    await s3.deleteObject(deleteParams).promise();
  } catch (err) {
    console.log('Error deleting objects: ' + err);
  }
}

async function removeVersions(id, userFolder) {
  const params = {
    Bucket: process.env.STORAGE_MELLONNSPEAKS3EU_BUCKETNAME,
    Prefix: 'private/' + userFolder + '/versions/' + id + '/',
  };
  try {
    const result = await s3.listObjectsV2(params).promise();
    const content = result.Contents;
    
    for (let file of content) {
      const deleteParams = {
        Bucket: process.env.STORAGE_MELLONNSPEAKS3EU_BUCKETNAME,
        Key: file.Key,
      };
      await s3.deleteObject(deleteParams).promise();
    }
  } catch (err) {
    console.log('Error while removing versions: ' + err);
  }
}

async function removeFromDataStore(id) {
  if(!client){
    client = new AWSAppSyncClient({
      url: process.env.API_MELLONNSPEAKEU_GRAPHQLAPIENDPOINTOUTPUT,
      region: process.env.REGION,
      auth: {
        type: "AWS_IAM",
        credentials: AWS.config.credentials
      },
      disableOffline: true
    });
  }

  try {
    const query = await client.query({
      query: queryRecording,
      variables: { id: id },
      fetchPolicy: 'no-cache'
    });
    if (query.data.getRecording) {
      const data = await client.mutate({
        mutation: deleteRecording,
        variables: { id: id, _version: query.data.getRecording._version },
        fetchPolicy: 'no-cache'
      });
      console.log('data: ', data);
    } else {
      console.log('No recording found');
    }
  } catch (err) {
    console.log(err);
  }
}
