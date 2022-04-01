require('es6-promise').polyfill();
require('isomorphic-fetch');
const AWSAppSyncClient = require('aws-appsync').default;
const AWS = require('aws-sdk');
const gql = require('graphql-tag');

let client;
const updateRecording = gql`
mutation UpdateRecording($id: ID!, $fileUrl: String, $_version: Int) {
  updateRecording(input: {id: $id, fileUrl: $fileUrl, _version: $_version}) {
    id
    fileUrl
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

exports.handler = async (event) => {
  const jobID = event.detail.TranscriptionJobName;
  
  const fileUrl = 'https://mellonnspeaks3bucketeu94145-prod.s3.eu-central-1.amazonaws.com/finishedJobs/' + jobID + '.json';
  
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
      variables: { id: jobID },
      fetchPolicy: 'no-cache'
    });
    console.log('Recording version: ' + query.data.getRecording._version);
    const data = await client.mutate({ 
      mutation: updateRecording,
      variables: { id: jobID, fileUrl: fileUrl, _version: query.data.getRecording._version },
      fetchPolicy: 'no-cache'
    });
    //console.log('data: ', data);
    return {
      statusCode: 200,
      body: data,
    }
  } catch (error) {
    return {
      statusCode: 500,
      body: 'error updating recording: ' + error,
    }
  }
}