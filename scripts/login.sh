if az account show &>/dev/null; then
		echo "You are already logged in to Azure..."
	else
		echo "Logging into Azure..."
			az login \
				--service-principal \
				-u ${spn} \
				-p ${spn_pw} \
				--tenant ${tenantId} &>/dev/null
			echo "Successfully logged into Azure..."
	fi