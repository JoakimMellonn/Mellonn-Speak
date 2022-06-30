/* Amplify Params - DO NOT EDIT
	AUTH_MELLONNSPEAKEU_USERPOOLID
	ENV
	REGION
Amplify Params - DO NOT EDIT */

/**
 * @type {import('@types/aws-lambda').APIGatewayProxyHandler}
 */

 const AWS = require('aws-sdk');
 AWS.config.update({region: process.env.REGION});
 
 const cognito = new AWS.CognitoIdentityServiceProvider({apiVersion: '2016-04-18'});
exports.handler = async (event) => {
    console.log(`EVENT: ${JSON.stringify(event)}`);
    const body = JSON.parse(event.body);
    let params;

    if (body.action == 'add') {
        params = {
            UserAttributes: [
                {
                    Name: 'custom:referGroup',
                    Value: body.referGroup
                },
                {
                    Name: 'custom:referrer',
                    Value: body.referrer
                },
                {
                    Name: 'custom:group',
                    Value: 'benefit'
                }
            ],
            UserPoolId: process.env.AUTH_MELLONNSPEAKEU_USERPOOLID,
            Username: body.email
        }
    } else if (body.action == 'remove') {
        params = {
            UserAttributes: [
                {
                    Name: 'custom:referGroup',
                    Value: ''
                },
                {
                    Name: 'custom:group',
                    Value: 'user'
                }
            ],
            UserPoolId: process.env.AUTH_MELLONNSPEAKEU_USERPOOLID,
            Username: body.email
        }
    } else {
        return {
            statusCode: 400,
            headers: {
                "Access-Control-Allow-Headers" : "Content-Type",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
            },
            body: JSON.stringify('Error: Invalid action')
        };
    }

    try {
        console.log(`PARAMS: ${JSON.stringify(params)}`);
        const result = await cognito.adminUpdateUserAttributes(params).promise();
        console.log(`RESULT: ${JSON.stringify(result)}`);

        return {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Headers" : "Content-Type",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
            },
            body: JSON.stringify('User successfully updated added/removed from group'),
        };
    } catch (err) {
        return {
            statusCode: 500,
            headers: {
                "Access-Control-Allow-Headers" : "Content-Type",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
            },
            body: JSON.stringify('Internal server error: ' + err),
        };
    }
};
