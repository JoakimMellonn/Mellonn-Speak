var AWSS3 = require('aws-sdk/clients/s3');
var s3 = new AWSS3();

exports.handler = async (event) => {
    let response;
    console.log(event.body);
    
    const e = JSON.parse(event.body);
    
    const action = e.action;
    const type = e.type;
    const code = e.code;
    const date = e.date;
    const uses = e.uses;
    const freePeriods = e.freePeriods;
    console.log('Action: ' + action + ', type: ' + type);
    
    const bucket = 'mellonnspeaks3bucketeu94145-prod';
    const key = 'public/data/promotions.json';
    
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
    
    const promotions = JSON.parse(data.Body.toString('utf-8')).promotions;
    console.log('Promotions: ' + JSON.stringify(promotions));
    let newPromotions = [];
    let changed = false;
    let alreadyExists = false;
    
    const length = promotions.length;
    for (let i = 0; i < length; i++) {
        const promotion = promotions[i];
        if (promotion.code == code) {
            alreadyExists = true;
        }
    }
    
    if (!alreadyExists && action == "add") {
        console.log('Adding new promotion');
        newPromotions = promotions;
        const promotion = {
            "type":type,
            "code":code,
            "date":date,
            "uses":uses,
            "freePeriods":freePeriods,
            "emails":[]
        };
        newPromotions.push(promotion);
        response = {
            statusCode: 200,
            body: 'Successfully added code: ' + code,
        };
        changed = true;
        putParams.Body = '{"promotions":' + JSON.stringify(newPromotions) + '}';
        console.log(JSON.stringify(putParams));
    } else if (alreadyExists && action == "remove") {
        console.log('Removing promotion');
        for (let i = 0; i < length; i++) {
            const promotion = promotions[i];
            if (promotion.code != code) {
                newPromotions.push(promotion);
            }
        }
        response = {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Headers" : "Content-Type",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
            },
            body: 'Successfully removed code: ' + code,
        };
        changed = true;
        putParams.Body = '{"promotions":' + JSON.stringify(newPromotions) + '}';
        console.log(JSON.stringify(putParams));
    }
    
    if (changed) {
        try {
            await s3.putObject(putParams).promise();
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
    } else if (alreadyExists && action == "add") {
        response = {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Headers" : "Content-Type",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
            },
            body: 'Promotion Code already exists!',
        };
    } else if (!alreadyExists && action == "remove") {
        response = {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Headers" : "Content-Type",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
            },
            body: "Promotion Code doesn't exists!",
        };
    } else {
        response = {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Headers" : "Content-Type",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
            },
            body: 'Success of some kind',
        };
    }
    console.log(response);
    return response;
};