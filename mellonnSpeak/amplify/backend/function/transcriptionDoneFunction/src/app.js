/*
Copyright 2017 - 2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the License. A copy of the License is located at
    http://aws.amazon.com/apache2.0/
or in the "license" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
*/


/* Amplify Params - DO NOT EDIT
	API_MELLONNSPEAKEU_GRAPHQLAPIENDPOINTOUTPUT
	API_MELLONNSPEAKEU_GRAPHQLAPIIDOUTPUT
	ENV
	REGION
Amplify Params - DO NOT EDIT */

/*const id = "cb3c063f-581d-4871-a543-6221861c868e";
const name = "Poul changed";

const axios = require('axios');
const gql = require('graphql-tag');
const graphql = require('graphql');
const { print } = graphql;*/

/*import AWSAppSyncClient, { AUTH_TYPE } from "aws-appsync"; 
const AWSAppSyncClient = require('aws-appsync').default;

const client = new AWSAppSyncClient({
  url: process.env.API_MELLONNSPEAKEU_GRAPHQLAPIENDPOINTOUTPUT,
  region: process.env.REGION,
  auth: {
      type: AUTH_TYPE.AWS_IAM
  }
});

const updateRecording = gql`
mutation updateRecording(
  $id: ID,
  $name: String,
  ) {
  updateRecording(input: {id: $id, name: $name}) {
    name
  }
}
`

client.hydrated().then(function (client) {
  // Now run a query
  client.query({ query: updateRecording, variables: { id, name } })
      .then(function log(data) {
          data = JSON.stringify(data);
          data = JSON.parse(data);
          if(data.data.listPosts) {
            console.log('(Query Data) All Posts ----------->', data.data.listPosts.items);
          }
          else {
              console.log("Error while fetching data");
          }
      })
      .catch(console.error);
});*/

/*exports.handler = async (event) => {
  console.log('event: ' + JSON.stringify(event));
  try {
    const graphqlData = await axios({
      url: process.env.API_MELLONNSPEAKEU_GRAPHQLAPIENDPOINTOUTPUT,
      method: 'post',
      headers: {
        'x-api-key': process.env.API_MELLONNSPEAKEU_GRAPHQLAPIKEYOUTPUT
      },
      data: {
        query: print(updateRecording),
        variables: {
          input: {
            id: id,
            name: name
          }
        }
      }
    });
    const body = {
      message: "successfully updated recording!"
    }
    return {
      statusCode: 200,
      body: JSON.stringify(body),
      headers: {
          "Access-Control-Allow-Origin": "*",
      }
    }
  } catch (err) {
    console.log('error updating recording: ', err);
    return {
      statusCode: 500,
      body: 'error updating recording: ' + err,
    }
  }
}*/
