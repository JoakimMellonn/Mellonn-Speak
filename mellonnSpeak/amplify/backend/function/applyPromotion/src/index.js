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
        body: JSON.stringify(""),
    };
    
    console.log(event.body);
    const e = JSON.parse(event.body);
    
    const code = e.code;
    const email = e.email;
    
    const bucket = process.env.STORAGE_MELLONNSPEAKS3EU_BUCKETNAME;
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
    
    let exists = false;
    let getPromotion;
    
    const length = promotions.length;
    for (let i = 0; i < length; i++) {
        const promotion = promotions[i];
        if (promotion.code == code) {
            exists = true;
            getPromotion = promotion;
        } else {
            newPromotions.push(promotion);
        }
    }
    
    if (exists) {
        if (getPromotion.emails.includes(email)) {
            response.body = "code already used";
        } else {
            if (getPromotion.uses == 0) {
                response.body = JSON.stringify("{\"type\":\"" + getPromotion.type + "\",\"freePeriods\":\"" + getPromotion.freePeriods + "\"}");
                getPromotion.emails.push(email);
                newPromotions.push(getPromotion);
            } else if (getPromotion.uses == 1) {
                response.body = JSON.stringify("{\"type\":\"" + getPromotion.type + "\",\"freePeriods\":\"" + getPromotion.freePeriods + "\"}");
            } else {
                response.body = JSON.stringify("{\"type\":\"" + getPromotion.type + "\",\"freePeriods\":\"" + getPromotion.freePeriods + "\"}");
                getPromotion.emails.push(email);
                getPromotion.uses--;
            }
            putParams.Body = '{"promotions":' + JSON.stringify(newPromotions) + '}';
            console.log(JSON.stringify(putParams));
            
            try {
                await s3.putObject(putParams).promise();
            } catch (e) {
                console.log(e);
                response.body = JSON.stringify("Internal server error, please contact support@mellonn.com");
            }
        }
    } else {
        response.body = JSON.stringify("code no exist");
    }
    console.log(JSON.stringify(response));
    return response;
};