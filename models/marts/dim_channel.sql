SELECT
	CHANNEL_ID,
	CHANNEL
FROM
	{{ ref('stg_channels') }}