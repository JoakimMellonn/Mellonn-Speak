const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const transcribe = new AWS.TranscribeService();
const docClient = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    console.log(JSON.stringify(event));
    const srcBucket = event.Records[0].s3.bucket.name;
    const objectKey = event.Records[0].s3.object.key;
    let fileURI = 's3://' + srcBucket + '/' + objectKey;
    fileURI = fileURI.replace('%3A', ':');
    const arr = objectKey.split('/');
    const userID = arr[1].replace('%3A', ':');
    const fileID = arr[3].split('.')[0];
    const fileType = arr[3].split('.')[1];
    
    let outputKey = 'public/finishedJobs/' + fileID + '.json';
    
    const dynamoParams = {
        TableName : 'Recording-hcqyho5atjcwbkgjc3hcepv66e-staging',
        Key: {
            id: fileID,
        },
    };
    const data = await getItem(dynamoParams);
    
    const speakerCount = data.Item.speakerCount;
    const languageCode = data.Item.languageCode;
    
    console.log(JSON.stringify(data));
    console.log('SpeakerCount: ' + speakerCount + ' languageCode: ' + languageCode);
    
    const transcribeParams = {
        TranscriptionJobName: fileID,
        Media: {
            MediaFileUri: fileURI,
        },
        OutputBucketName: srcBucket,
        OutputKey: outputKey,
        LanguageCode: languageCode,
        Settings: {
            MaxSpeakerLabels: speakerCount,
            ShowSpeakerLabels: true,
        },
    };
    
    console.log(JSON.stringify(transcribeParams));
    console.log('userID: ' + userID + ' fileID: ' + fileID + ' fileType: ' + fileType);
    
    await new Promise((resolve, reject) => {
        transcribe.startTranscriptionJob(transcribeParams, function (err, data) {
            if (err) {
                reject(err);
            } // an error occurred
            else {
                console.log(data); // successful response
                resolve(data);
            }
        });
    });
};

async function getItem(params){
    try {
        const data = await docClient.get(params).promise();
        return data;
    } catch (err) {
        return err;
    }
}