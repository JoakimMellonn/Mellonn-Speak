export type AmplifyDependentResourcesAttributes = {
    "auth": {
        "MellonnSpeakEU": {
            "IdentityPoolId": "string",
            "IdentityPoolName": "string",
            "UserPoolId": "string",
            "UserPoolArn": "string",
            "UserPoolName": "string",
            "AppClientIDWeb": "string",
            "AppClientID": "string"
        }
    },
    "api": {
        "mellonnspeakeu": {
            "GraphQLAPIIdOutput": "string",
            "GraphQLAPIEndpointOutput": "string"
        },
        "stripePayment": {
            "RootUrl": "string",
            "ApiName": "string",
            "ApiId": "string"
        },
        "stripeFunction": {
            "RootUrl": "string",
            "ApiName": "string",
            "ApiId": "string"
        }
    },
    "storage": {
        "mellonnSpeakS3EU": {
            "BucketName": "string",
            "Region": "string"
        }
    },
    "function": {
        "MellonnSpeakEUFunction": {
            "Name": "string",
            "Arn": "string",
            "Region": "string",
            "LambdaExecutionRole": "string"
        },
        "stripePaymentFunction": {
            "Name": "string",
            "Arn": "string",
            "Region": "string",
            "LambdaExecutionRole": "string"
        },
        "stripeFunction": {
            "Name": "string",
            "Arn": "string",
            "Region": "string",
            "LambdaExecutionRole": "string"
        }
    }
}