/* Amplify Params - DO NOT EDIT
	ENV
	REGION
	STORAGE_MELLONNSPEAKS3EU_BUCKETNAME
Amplify Params - DO NOT EDIT */

const ffmpeg = require('fluent-ffmpeg');
const fs = require('fs');
var path = require('path');
var AWSS3 = require('aws-sdk/clients/s3');
var s3 = new AWSS3();

/**
 * @type {import('@types/aws-lambda').APIGatewayProxyHandler}
*/
exports.handler = async (event) => {
    console.log(`EVENT: ${JSON.stringify(event)}`);
    const e = JSON.parse(event.body);
    const inputString = e.inputString;
    const outputString = e.outputString;
    const inputKey = e.inputKey;

    let tempDir;
    if (process.env.DEV && process.env.DEV === 'Yes') {
        tempDir = path.join(__dirname, `../../tmp/`);
    } else {
        tempDir = '/tmp/';
    }

    let statusCode = 500;
    let returnBody = JSON.stringify('Nothing happened');

    var getExeParams = {
        Bucket: process.env.STORAGE_MELLONNSPEAKS3EU_BUCKETNAME,
        Key: 'public/convert/exe/ffmpeg',
    }

    var getAudioParams = {
        Bucket: process.env.STORAGE_MELLONNSPEAKS3EU_BUCKETNAME,
        Key: 'public/' + inputKey,
    };

    try {
        const data = (await s3.getObject(getAudioParams).promise()).Body;
        const inputPath = tempDir + inputString;
        fs.writeFileSync(inputPath, data);
        
        ffmpeg.setFfmpegPath('/opt/bin/ffmpeg');
        
        await new Promise((resolve, reject) => {
            ffmpeg(inputPath)
                .audioCodec('pcm_s16le')
                .audioChannels(1)
                .audioFrequency(16000)
                .save(tempDir + 'output.wav')
                .on('end', () => {
                    resolve('Success!');
                })
                .on('error', (error) => {
                    reject('Something happened: ' + error);
                });
        }).catch((e) => {
            console.log('Something went wrong while converting file: ' + e);
            if (e != 'Something happened: Error: spawn /tmp/ffmpeg EACCES') {
                returnBody = JSON.stringify("Something went wrong while converting file: " + e);
                return;
            }
        }).then(async () => {
            const buffer = fs.readFileSync(tempDir + 'output.wav');
            var putParams = {
                Bucket: process.env.STORAGE_MELLONNSPEAKS3EU_BUCKETNAME,
                Key: 'public/convert/output/' + outputString,
                Body: buffer
            };
            await s3.putObject(putParams).promise();
            statusCode = 200;
            returnBody = JSON.stringify('Yay!');
        });
        
    } catch (e) {
        console.log('Something went wrong: ' + e);
        returnBody = JSON.stringify("Something went wrong: " + e);
    }
    
    return {
        statusCode: statusCode,
        headers: {
            "Access-Control-Allow-Headers": "*",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
        },
        body: returnBody
    };
}