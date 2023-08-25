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

const notificationMessages = [
    "Voila! Your transcription is hot off the AI oven 🎉",
    "Drumroll, please! Your transcription is ready to rock 🥁",
    "Ta-da! Your transcription just did a magic trick 🪄",
    "Your transcription is here, doing the robot dance 🤖",
    "Guess what? Your transcription is now fluent in AI-speak! 🤖💬",
    "High-five to AI magic! Your transcription is good to go 🙌",
    "Woop woop! Your transcription is all dressed up and ready to party 🎩🎊",
    "Ding ding! Your transcription just pulled off a speedy makeover ⚡"
];

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
        console.log(`Updating file url to ${fileUrl}`);
        const data = await client.mutate({
            mutation: updateRecording,
            variables: { id: jobID, fileUrl: fileUrl, _version: query.data.getRecording._version },
            fetchPolicy: 'no-cache'
        });
        await sendNotification(ownerId, jobID);
        //console.log('data: ', data);
        return {
            statusCode: 200,
            body: data,
        }
    } catch (error) {
        console.log(`Error: ${error}`);
        return {
            statusCode: 500,
            body: 'error updating recording: ' + error,
        }
    }
}

//Sends a push notification with pinpoint
async function sendNotification(ownerId, recordingId) {
    const title = notificationMessages[Math.floor(Math.random() * notificationMessages.length)];
    const sendMessagesParams = {
        ApplicationId: process.env.PINPOINT_APP_ID,
        SendUsersMessageRequest: {
            Users: {
                [ownerId]: {}
            },
            MessageConfiguration: {
                APNSMessage: {
                    Action: 'DEEP_LINK',
                    Title: title,
                    SilentPush: false,
                    Body: 'Tap to open the transcription.',
                    Url: `speak://recording/${recordingId}`
                },
                GCMMessage: {
                    Action: 'DEEP_LINK',
                    Title: title,
                    SilentPush: false,
                    Body: 'Tap to open the transcription.',
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
