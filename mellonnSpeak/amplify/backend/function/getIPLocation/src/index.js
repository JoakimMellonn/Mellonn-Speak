/*
Use the following code to retrieve configured secrets from SSM:

const aws = require('aws-sdk');

const { Parameters } = await (new aws.SSM())
  .getParameters({
    Names: ["apiKey"].map(secretName => process.env[secretName]),
    WithDecryption: true,
  })
  .promise();

Parameters will be of the form { Name: 'secretName', Value: 'secretValue', ... }[]
*/

const https = require('https');

function getRequest(url) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, res => {
      let rawData = '';

      res.on('data', chunk => {
        rawData += chunk;
      });

      res.on('end', () => {
        try {
          resolve(JSON.parse(rawData));
        } catch (err) {
          reject(new Error(err));
        }
      });
    });

    req.on('error', err => {
      reject(new Error(err));
    });
  });
}

/**
 * @type {import('@types/aws-lambda').APIGatewayProxyHandler}
 */
exports.handler = async (event) => {
  const aws = require('aws-sdk');

  const { Parameters } = await (new aws.SSM())
    .getParameters({
      Names: ["apiKey"].map(secretName => process.env[secretName]),
      WithDecryption: true,
    })
    .promise();

  const ip = JSON.parse(event.body).ip;
  const apiKey = Parameters[0].Value;
  const url = `https://api.ipregistry.co/${ip}?key=${apiKey}`;

  try {
    const result = await getRequest(url);

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*"
      }, 
      body: JSON.stringify(result),
    };

  } catch (err) {
    console.log(`Error while fetching data: ${err}`);

    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*"
      }, 
      body: JSON.stringify(err),
    };
  }
};
