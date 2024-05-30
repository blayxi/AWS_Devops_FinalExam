import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';

export class CdkWorkshopStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Create a VPC
    const vpc = new ec2.Vpc(this, 'MyVpc', {
      cidr: '10.30.0.0/16',
      maxAzs: 2,
      natGateways: 1,
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'public-subnet',
          subnetType: ec2.SubnetType.PUBLIC,
        },
      ],
    });

    // Create an EC2 instance in the public subnet
    new ec2.Instance(this, 'MyInstance', {
      vpc: vpc,
      instanceType: ec2.InstanceType.of(
        ec2.InstanceClass.T2,
        ec2.InstanceSize.MICRO,
      ),
      machineImage: new ec2.AmazonLinuxImage(),
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
    });

    // Create an SQS Queue
    new sqs.Queue(this, 'MyQueue', {
      visibilityTimeout: cdk.Duration.seconds(300),
    });

    // Create an SNS Topic
    new sns.Topic(this, 'MyTopic');

    // Create a Secrets Manager secret
    new secretsmanager.Secret(this, 'MetroDbSecrets', {
      secretName: 'metrodb-secrets',
      generateSecretString: {
        secretStringTemplate: JSON.stringify({ username: 'blaycdk' }),
        generateStringKey: 'password',
        passwordLength: 12,
        excludePunctuation: true,
      },
    });
  }
}

const app = new cdk.App();
new CdkWorkshopStack(app, 'CdkWorkshopStack', {
  stackName: 'CdkWorkshopStack'
});
