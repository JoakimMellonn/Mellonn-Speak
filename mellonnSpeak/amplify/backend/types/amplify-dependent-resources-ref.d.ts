export type AmplifyDependentResourcesAttributes = {
    "auth": {
        "MellonnSpeakEU": {
            "IdentityPoolId": "string",
            "IdentityPoolName": "string",
            "UserPoolId": "string",
            "UserPoolArn": "string",
            "UserPoolName": "string",
            "AppClientIDWeb": "string",
            "AppClientID": "string",
            "CreatedSNSRole": "string"
        }
    },
    "api": {
        "mellonnspeakeu": {
            "GraphQLAPIIdOutput": "string",
            "GraphQLAPIEndpointOutput": "string"
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
        "stripeFunction": {
            "Name": "string",
            "Arn": "string",
            "Region": "string",
            "LambdaExecutionRole": "string"
        },
        "transcriptionDoneFunction": {
            "Name": "string",
            "Arn": "string",
            "Region": "string",
            "LambdaExecutionRole": "string"
        }
    },
    "analytics": {
        "SpeakAnalytics": {
            "Region": "string",
            "Id": "string",
            "appName": "string"
        }
    }
}