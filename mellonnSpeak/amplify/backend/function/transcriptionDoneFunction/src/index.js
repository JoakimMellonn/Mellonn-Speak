require('es6-promise').polyfill();
require('isomorphic-fetch');
const AWSAppSyncClient = require('aws-appsync').default;
const AWS = require('aws-sdk');
const gql = require('graphql-tag');
const pinpoint = new AWS.Pinpoint();

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
    owner
  }
}
`;

exports.handler = async (event) => {
  const jobID = event.detail.TranscriptionJobName;

  const fileUrl = 'https://mellonnspeaks3bucketeu102306-staging.s3.eu-central-1.amazonaws.com/finishedJobs/' + jobID + '.json';

  if (!client) {
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
    console.log(`Query data: ${JSON.stringify(query.data)}`);
    const ownerId = query.data.getRecording.owner;
    await sendNotification(ownerId, jobID);

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

//Sends a push notification with pinpoint
async function sendNotification(ownerId, recordingId) {
  const sendMessagesParams = {
    ApplicationId: process.env.PINPOINT_APP_ID,
    SendUsersMessageRequest: {
      Users: {
        [ownerId]: {}
      },
      MessageConfiguration: {
        APNSMessage: {
          Action: 'DEEP_LINK',
          Title: 'Recording has been transcribed!',
          SilentPush: false,
          Body: 'Our AI is done doing its part.',
          Url: `speak://recording/${recordingId}`
        },
        GCMMessage: {
          Action: 'DEEP_LINK',
          Title: 'Recording has been transcribed!',
          SilentPush: false,
          Body: 'Our AI is done doing its part.',
          Url: `speak://recording/${recordingId}`
        }
      }
    }
  };

  console.log('sendMessagesParams', JSON.stringify(sendMessagesParams));
  try {
    const result = await pinpoint.sendUsersMessages(sendMessagesParams).promise();
    console.log('result', JSON.stringify(result));
  } catch (err) {
    console.log(`Error while sending message ${err}`);
  }
}
