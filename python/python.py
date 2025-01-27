import boto3

def lambda_handler(event, context):
    # Initialize RDS client
    rds_client = boto3.client('rds')
    
    # Replace with your RDS cluster identifier
    cluster_identifier = 'intella-apse2-aurora-mysql'
    
    try:
        # Get the status of the cluster
        response = rds_client.describe_db_clusters(
            DBClusterIdentifier=cluster_identifier
        )
        cluster_status = response['DBClusters'][0]['Status']
        print(f"Cluster status: {cluster_status}")
        
        # Check if the cluster is running
        if cluster_status == 'available':
            print(f"Cluster {cluster_identifier} is running. Stopping it now.")
            rds_client.stop_db_cluster(DBClusterIdentifier=cluster_identifier)
            return {
                'statusCode': 200,
                'body': f"RDS cluster {cluster_identifier} was running and is now stopping."
            }
        else:
            print(f"Cluster {cluster_identifier} is not running. Current status: {cluster_status}")
            return {
                'statusCode': 200,
                'body': f"RDS cluster {cluster_identifier} is not running. Current status: {cluster_status}."
            }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Error occurred: {str(e)}"
        }