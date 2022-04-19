AerisWeather Webhooks Tutorial
==============================

[AerisWeather Webhooks][0] provide timely notification of the weather
events that you care about most. Skip complicated polling. Stop
worrying about whether you got every alert or lightning strike.
Get all of your events delivered directly (and fast) with webhooks.
In this post, we'll cover setting up your own webhook endpoint from
scratch on Amazon Web Services (AWS). We'll also go over some best
practices, so that you get the most out of AerisWeather Webhooks.

Before Getting Started
----------------------

There are some things you should know before going through this tutorial.

First, creating resources on AWS _may incur charges_. If you're following this
tutorial closely, your utilization should fall within the AWS "free tier" for
Lambda and API Gateway. If you have maxed out free tier utilization, the
resulting charges should be no more than a few cents. That said, AerisWeather
cannot be responsible for the cost incurred by following this tutorial. You may
wish to configure a budget within AWS to notify you if your monthly spend
surpasses some threshold.

Second, this repository provides supplemental content to get your webhooks demo
endpoint up and running _quickly_. To that end, we cover only the absolute
necessities to configure a webhooks endpoint. This tutorial is **not** intended
for direct deployment into a production environment.

Prerequisites
-------------

With that out of the way, here is what you will need to follow along with this
tutorial:

* An AWS account with [administrator credentials configured locally][1]
* The following software installed:
    * `git`
    * [Python][2]
    * [Hashicorp Terraform][3]
* Basic familiarity with Python

Once the prerequisites are met, it's time to deploy the infrastructure!

Deploy the Infrastructure
-------------------------

In this repository, change into the `terraform/` directory and run
`terraform apply`. Terraform will create a Lambda function and API Gateway
in AWS to serve as a demo webhook endpoint.

**Heads up!** You will want to run `terraform destroy` in the `terraform/`
directory when you are all done with this demo. That will ensure the demo
resources are destroyed and that you will not be billed for them. You can
recreate them at any time!

When Terraform finishes, it will print out the URL to your demo webhook
endpoint. It will look something like this:

    api_gateway_webhook_url = "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/tutorial/webhook"

Now you're ready to start making requests.

Make a Test Request
-------------------

You can make a test request against your endpoint by running the
`post-to-webhook` script in this repository:

    ./post-to-webhook data/wind-sps.txt

Will post the contents of the file `data/wind-sps.txt` to the endpoint. With
the demo code in this repository, you should see:

    {"error": null, "response": {"message": "posted data contained alert types: SP.S, WI.W"}}


This response has come from the webhook endpoint that you deployed. The code
that powers the endpoint is in `webhook.py`. AWS Lambda is configured to invoke
the `lambda_handler` function to handle requests made against your webhook
endpoint.

There are a couple other test data files in the `data/` directory. Try posting
those and see what happens!

Exercise: Modify `webhook.py`
-----------------------------

The current webhook endpoint code takes a data payload in the form returned
by the Aeris API (as AerisWeather Webhooks will provide) and determines what
types of alerts are contained within.

Modify `webhook.py` so that it returns the name of the place where the alert is
issued, instead.

To test locally, you can run `./webhook.py data/wind-sps.txt` to simulate
POSTing `data/wind-sps.txt` to the webhook endpoint. It doesn't actually POST
anything anywhere; it just runs the script in a different mode.

When you want to publish your changes to the webhook endpoint, change into the
`terraform/` directory and run `terraform apply` again. After you publish the
changes, you will be able to run

    ./post-to-webhook data/wind-sps.txt

to send the data to your live webhook endpoint.

Recap
-----

In this tutorial, you learned how deploy a webhook endpoint powered by Lambda
and API Gateway using Terraform. You performed some basic processing on POSTed
alerts and returned a response.

Next Steps
----------

To build out your own webhook endpoint, check out the definitions in
`terraform/` as a starting point. There are many ways to provide a webhook
endpoint service -- the way we suggested here is easy and cheap for low-volume
services.

You may also wish to take the example script provided here and convert it to
another language supported by Lambda.

When you feel like you have a solid grasp on configuring a webhook endpoint,
check out the list of best practices below.

**Don't forget to clean up the infrastructure you deployed** by running
`terraform destroy` in the `terraform/` directory when you are finished!

Best Practices
--------------

For the best experience with AerisWeather Webhooks, make sure your endpoint
adheres to the best practices outlined here. Ensure that your webhook
endpoint...

* ...returns an appropriate HTTP status code.
  * 200, 202, 204 status codes indicate success (with some minor differences).
  * 400 indicates that the request format wasn't what you expected.
  * 401 indicates that API key provided to your endpoint was incorrect (i.e.
    authentication failed)
  * 500 indicates that your service experienced an internal error that it could
    not handle.

* ...returns a response quickly. **Do not** perform slow processing on weather
  events immediately when they hit your endpoint. Instead, store the events
  somewhere and process them via another mechanism.

* ...is available most of the time. While AerisWeather Webhooks will retry if
  your service encounters an error, we will not perform retries forever!


[0]: https://www.aerisweather.com/support/docs/api/reference/webhooks-and-pushed-data/
[1]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds
[2]: https://www.python.org/
[3]: https://www.terraform.io/
