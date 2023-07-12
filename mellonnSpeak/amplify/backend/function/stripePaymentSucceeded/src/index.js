/*
Use the following code to retrieve configured secrets from SSM:

const aws = require('aws-sdk');

const { Parameters } = await (new aws.SSM())
  .getParameters({
    Names: ["stripeKey"].map(secretName => process.env[secretName]),
    WithDecryption: true,
  })
  .promise();

Parameters will be of the form { Name: 'secretName', Value: 'secretValue', ... }[]
*/
/**
 * @type {import('@types/aws-lambda').APIGatewayProxyHandler}
 */
exports.handler = async (event) => {
  const aws = require('aws-sdk');

  const { Parameters } = await (new aws.SSM())
    .getParameters({
        Names: ["stripeKey"].map(secretName => process.env[secretName]),
        WithDecryption: true,
    })
    .promise();

  const stripe = require("stripe")(Parameters[0].Value);
  // console.log(`EVENT: ${JSON.stringify(event)}`);
  const paymentIntent = JSON.parse(event.body).data.object;
  // console.log(`Payment Intent: ${JSON.stringify(paymentIntent)}`);
  const id = paymentIntent.id;
  const calculation = paymentIntent.metadata.calculation;

  try {
    // console.log("Creating transaction...");
    const transaction = await stripe.tax.transactions.createFromCalculation({
      calculation: calculation,
      reference: id,
      expand: ["line_items"],
    });
    // console.log(`Transaction: ${JSON.stringify(transaction)}`);

    const paymentIntent = await stripe.paymentIntents.update(
      id, {
        metadata: {
          tax_transaction: transaction.id,
        },
      }
    );
    console.log(`New Payment Intent: ${JSON.stringify(paymentIntent)}`);

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*"
      },
      body: JSON.stringify('Successfully registered the transaction!'),
    };
  } catch (err) {
    console.log(`${err}`)
    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*"
      },
      body: JSON.stringify(`${err}`),
    };
  }
};
