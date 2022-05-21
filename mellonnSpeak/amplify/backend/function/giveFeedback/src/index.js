var aws = require("aws-sdk");
var ses = new aws.SES({ region: "eu-central-1" });

exports.handler = async (event) => {
    console.log(event.body);
    const e = JSON.parse(event.body);
    
    const email = e.email;
    const name = e.name;
    const where = e.where;
    const message = e.message;
    const accepted = e.accepted;
    
    var params = {
        Destination: {
            ToAddresses: [
                "support@mellonn.com",
            ]
        },
        Template: 'feedbackEmail',
        TemplateData: JSON.stringify({
            "email": email,
            "name": name,
            "where": where,
            "message": message,
            "accepted": accepted,
        }),
        ReplyToAddresses: [
            'support@mellonn.com',
        ],
        Source: "no-reply@mellonn.com",
    };
    
    console.log(JSON.stringify(params));
    
    let response = {};
    
    try {
        const data = await ses.sendTemplatedEmail(params).promise();
        console.log("SES SUCCESS: " + JSON.stringify(data));
        response = {
            statusCode: 200,
            body: JSON.stringify(JSON.stringify(data)),
        };
    } catch (err) {
        console.log("SES ERROR: " + err);
        response = {
            statusCode: 500,
            body: err,
        };
    }
    console.log(response);
    return response;
};