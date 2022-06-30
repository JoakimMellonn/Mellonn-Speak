var AWSS3 = require('aws-sdk/clients/s3');
var s3 = new AWSS3();

exports.handler = async (event) => {
    let response;
    
    console.log(event.body);
    const e = JSON.parse(event.body);
    
    const code = e.code;
    const email = e.email;
    
    const bucket = 'mellonnspeaks3bucketeu102306-staging';
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
            response = {
                statusCode: 200,
                body: "code already used",
            };
        } else {
            if (getPromotion.uses == 0) {
                response = {
                    statusCode: 200,
                    body: "{\"type\":\"" + getPromotion.type + "\",\"freePeriods\":\"" + getPromotion.freePeriods + "\"}"
                };
                getPromotion.emails.push(email);
                newPromotions.push(getPromotion);
            } else if (getPromotion.uses == 1) {
                response = {
                    statusCode: 200,
                    body: "{\"type\":\"" + getPromotion.type + "\",\"freePeriods\":\"" + getPromotion.freePeriods + "\"}"
                };
            } else {
                response = {
                    statusCode: 200,
                    body: "{\"type\":\"" + getPromotion.type + "\",\"freePeriods\":\"" + getPromotion.freePeriods + "\"}"
                };
                getPromotion.emails.push(email);
                getPromotion.uses--;
            }
            putParams.Body = '{"promotions":' + JSON.stringify(newPromotions) + '}';
            console.log(JSON.stringify(putParams));
            
            try {
                await s3.putObject(putParams).promise();
            } catch (e) {
                console.log(e);
                response = {
                    statusCode: 500,
                    body: "Internal server error, please contact joakim@mellonn.com",
                };
            }
        }
    } else {
        response = {
            statusCode: 200,
            body: "code no exist",
        };
    }
    console.log(JSON.stringify(response));
    return response;
};