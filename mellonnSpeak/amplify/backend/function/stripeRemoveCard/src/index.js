
exports.handler = async (event) => {
    const stripe = require("stripe")(process.env.stripeKey);
    const cardId = JSON.parse(event.body).cardId;
    
    try {
        await stripe.paymentMethods.detach({cardId});
        return {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
            },
            body: JSON.stringify({
                message: 'Card removed',
            })
        }
    } catch(err) {
        console.log(err);
        return {
            statusCode: 500,
            headers: {
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
            },
            body: JSON.stringify({
                error: err.message,
            })
        }
    }
};
