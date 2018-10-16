import boto3
c = boto3.Session(region_name='eu-west-1', profile_name='default').client('ec2')
response = c.describe_security_groups()

for x in response['SecurityGroups']:
    for y in x['IpPermissions']:
        try:
            if y['ToPort'] == 22:
                print("Port 22: {}, {}".format(x['GroupId'], y['IpRanges']))
        except KeyError:
            pass

# Output:
# Port 22: sg-00000001, [{u'CidrIp': '0.0.0.0/0'}, {u'CidrIp': '1.2.3.4/32'}]
# Port 22: sg-00000002, [{u'Description': 'Description 1', u'CidrIp': '1.2.3.4/32'}]
