const AWS = require('aws-sdk');
const s3 = new AWS.S3();
const transcribe = new AWS.TranscribeService();
const docClient = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    const srcBucket = event.Records[0].s3.bucket.name;
    const objectKey = event.Records[0].s3.object.key;
    const arr = objectKey.split('/');
    const objectName = arr[2];
    const userFolder = arr[1];
    const fileURI = 's3://' + srcBucket + '/' + objectKey;
    const fileType = objectName.split('.').pop();
    
    const outputBucket = 's3://' + srcBucket + '/' + userFolder;
    const jobName = 'transcription-' + objectName;
    const originalFile = objectName.split('-').pop();
    
    if (fileType == 'json') {
        updateItem(originalFile, fileURI);
    } else {
        const dynamoParams = {
            TableName : 'Recording-hcqyho5atjcwbkgjc3hcepv66e-staging',
            Key: {
                fileKey: {objectName},
            },
        };
        const data = getItem(dynamoParams);
        const speakerCount = data.speakerCount;
        const languageCode = data.languageCode;
        
        const transcribeParams = {
            TranscriptionJobName: jobName,
            Media: fileURI,
            OutputBucketName: outputBucket,
            LanguageCode: languageCode,
            Settings: {
                MaxSpeakerLabels: speakerCount,
            },
        };
    }
    
    
    console.log('objectName: ' + objectName + ', objectKey: ' + objectKey + ', userFolder: ' + userFolder + ', fileType: ' + fileType);
};

async function getItem(params){
    try {
        const data = await docClient.get(params).promise();
        return data;
    } catch (err) {
        return err;
    }
}

async function updateItem(fileName, uri) {
    fileName = fileName.replace('+', ' ');
    const params = {
        TableName : 'Recording-hcqyho5atjcwbkgjc3hcepv66e-staging',
        Key: {
            fileKey: {fileName},
        },
        UpdateExpression: "set fileUrl = :u",
        ExpressionAttributeValues:{
            ":u": uri,
        },
    };
    
    docClient.update(params, function(err, data) {
        if (err) {
            console.error("Unable to update item. Error JSON:", JSON.stringify(err, null, 2));
        } else {
            console.log("UpdateItem succeeded:", JSON.stringify(data, null, 2));
        }
    });
}