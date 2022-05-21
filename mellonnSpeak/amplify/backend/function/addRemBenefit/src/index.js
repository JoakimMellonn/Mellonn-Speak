var AWSS3 = require('aws-sdk/clients/s3');
var s3 = new AWSS3();

exports.handler = async (event) => {
    let response;
    
    console.log(event.body);
    const e = JSON.parse(event.body);
    
    const action = e.action;
    const email = e.email;
    
    const bucket = 'mellonnspeaks3bucketeu94145-prod';
    const key = 'public/data/benefitUsers.json';
    
    var getParams = {
        Bucket: bucket,
        Key: key,
    };
    var putParams = {
        Bucket: bucket,
        Key: key,
        Body: '',
        ContentType: 'application/json'
    };
    
    const data = await s3.getObject(getParams).promise();
    
    const emails = JSON.parse(data.Body.toString('utf-8')).emails;
    let newEmails = [];
    let changed = false;
    
    console.log('Emails: ' + emails);
    
    
    
    if (action == 'add') {
        console.log('Adding email: ' + email);
        let alreadyExcists = false;
        let length = emails.length;
        for (let i = 0; i < length; i++) {
            if (emails[i] == email) {
                alreadyExcists = true;
                changed = false;
            }
        }
        
        if (!alreadyExcists) {
            newEmails = emails;
            newEmails.push(email);
            putParams.Body = '{"emails":' + JSON.stringify(newEmails) + '}';
            changed = true;
        }
        console.log(JSON.stringify(putParams));
    } else {
        console.log('Removing email: ' + email);
        let length = emails.length;
        for (let i = 0; i < length; i++) {
            const current = emails[i];
            if (current != email) {
                console.log('Adding: ' + current);
                newEmails.push(current);
            } else {
                changed = true;
            }
        }
        putParams.Body = '{"emails":' + JSON.stringify(newEmails) + '}';
        console.log(JSON.stringify(putParams));
    }
    
    if (changed) {
        try {
            await s3.putObject(putParams).promise();
            response = {
                statusCode: 200,
                headers: {
                    "Access-Control-Allow-Headers" : "Content-Type",
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
                },
                body: 'Success!',
            };
        } catch (e) {
            console.log(e);
            response = {
                statusCode: 500,
                headers: {
                    "Access-Control-Allow-Headers" : "Content-Type",
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
                },
                body: 'Internal server error, please contact joakim@mellonn.com',
            };
        }
    } else {
        response = {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Headers" : "Content-Type",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
            },
            body: 'Success!',
        };
    }
    return response;
};