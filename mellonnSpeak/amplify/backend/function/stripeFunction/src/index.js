const awsServerlessExpress = require('aws-serverless-express');
const app = require('./app');
const stripeKey = "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";
const stripeTestKey = "sk_test_51K1CskBLC2uA76LRFJrdtxDlDy1lLjry796RWVBInLSyj0tLd3hfuRrVopnNZZTsHUF2FXWVPU54jcIiXomYcWnp00WPxvYUl3";

exports.handler = async (event, context) => {
    console.log(`EVENT: ${JSON.stringify(event)}`);
    const stripe = require("stripe")(stripeKey);
    
    const json = JSON.parse(event.body.replace(/'/g, '"'));
    console.log(JSON.stringify(json));
    
    let email = json.email;
    let amount = json.amount;
    let periods = json.periods;
    let currency = json.currency;
    let prodID = json.prodID;
    let priceID = json.priceID;
    let unitAmount = json.unitAmount;
    let prodName = json.prodName;
    
    let desc = "{\"email\":\"" + email + "\",\"item\":\"" + prodName + "\",\"quantity\":\"" + periods + "\",\"itemPrice\":\"" + unitAmount + "\"}";
    
    console.log('email: ' + email + ', amount: ' + amount + ', periods: ' + periods + ', currency: ' + currency + ', prodID: ' + prodID + ', priceID: ' + priceID + ', unitAmount: ' + unitAmount + ', prodName: ' + prodName);
    console.log('Description: ' + desc);

    try {
        let customerId;

        //Gets the customer who's email id matches the one sent by the client
        const customerList = await stripe.customers.list({
            email: email,
            limit: 1
        });
        
        console.log('json: ' + JSON.stringify(customerList.data));
                
        //Checks the if the customer exists, if not creates a new customer
        if (customerList.data.length !== 0) {
            customerId = customerList.data[0].id;
            console.log('ID: ' + customerId);
        }
        else {
            const customer = await stripe.customers.create({
                email: email
            });
            customerId = customer.id;
        }

        //Creates a temporary secret key linked with the customer 
        const ephemeralKey = await stripe.ephemeralKeys.create(
            { customer: customerId },
            { apiVersion: '2020-08-27' }
        );

        //Creates a new payment intent with amount passed in from the client
        const paymentIntent = await stripe.paymentIntents.create({
            amount: parseInt(amount, 10),
            currency: currency,
            customer: customerId,
            description: desc,
        });

        console.log('Payment intent: ' + paymentIntent.client_secret + ', EphemeralKey: ' + ephemeralKey.secret + ', Customer: ' + customerId);

        return {
            statusCode: 200, // http status code
            body: JSON.stringify({
                paymentIntent: paymentIntent.client_secret,
                ephemeralKey: ephemeralKey.secret,
                customer: customerId,
                success: true,
            }),
        };

    } catch (error) {
        console.log('ERROR: ' + error.message);
        return {
            statusCode: 404,
            body: JSON.stringify({success: false, error: error.message}),
        };
    }
};