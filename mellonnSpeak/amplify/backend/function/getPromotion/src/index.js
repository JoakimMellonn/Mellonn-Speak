/* Amplify Params - DO NOT EDIT
	ENV
	REGION
	STORAGE_MELLONNSPEAKS3EU_BUCKETNAME
Amplify Params - DO NOT EDIT */

var AWSS3 = require('aws-sdk/clients/s3');
var s3 = new AWSS3();

exports.handler = async (event) => {
    let response = {
        statusCode: 200,
        headers: {
            "Access-Control-Allow-Headers" : "Content-Type",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
        },
        body: "",
    };
    const e = JSON.parse(event.body);
    
    const code = e.code;
    const email = e.email;
    
    const bucket = process.env.STORAGE_MELLONNSPEAKS3EU_BUCKETNAME;
    const key = 'public/data/promotions.json';
    
    var getParams = {
        Bucket: bucket,
        Key: key,
    };
    
    const data = await s3.getObject(getParams).promise();
    
    const promotions = JSON.parse(data.Body.toString('utf-8')).promotions;
    console.log('Promotions: ' + JSON.stringify(promotions));
    
    let exists = false;
    let getPromotion;
    
    const length = promotions.length;
    for (let i = 0; i < length; i++) {
        const promotion = promotions[i];
        if (promotion.code == code) {
            exists = true;
            getPromotion = promotion;
        }
    }
    
    if (exists) {
        if (getPromotion.emails.includes(email)) {
            response.body = "code already used";
        } else {
            response.body = JSON.stringify({
                type: getPromotion.type,
                freePeriods: getPromotion.freePeriods,
                referrer: getPromotion.referrer ?? '',
                referGroup: getPromotion.referGroup ?? ''
            });
        }
    } else {
        response.body = "code no exist";
    }
    console.log(JSON.stringify(response));
    return response;
};