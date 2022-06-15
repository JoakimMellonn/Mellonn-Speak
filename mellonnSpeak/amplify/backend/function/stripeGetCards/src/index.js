exports.handler = async (event) => {
    const stripe = require("stripe")(process.env.stripeKey);
    const customerId = JSON.parse(event.body).customerId;

    let cards;

    try {
        cards = await stripe.paymentMethods.list({
            customer: customerId,
            type: 'card',
        });
    } catch (err) {
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
    
    return {
        statusCode: 200,
        headers: {
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST,PUT,GET"
        },
        body: {
            cards: 'HELLO',
        },
    };
};
