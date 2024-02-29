#!/bin/bash

RED=$(tput setaf 9)
GREEN=$(tput setaf 10)
YELLOW=$(tput setaf 11)
BLUE=$(tput setaf 12)
MAGENTA=$(tput setaf 13)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
NC=$(tput sgr0) # No Color
CR=`echo $'\n.'`
CR=${CR%.}

# Prompt user for local path
read -p "${CR}${RED}Enter the local path to mount your OCI bucket:${NC}${CR}" LOCAL_PATH
echo

# Check if the local path already exists and is empty
if [ -d "$LOCAL_PATH" ]; then
    if [ "$(ls -A $LOCAL_PATH)" ]; then
        echo "${RED}Error: The specified path already exists and is not empty. Exiting.${NC}"
        exit 1
    fi
else
    sudo mkdir -p $LOCAL_PATH
    sudo chown -R $USER:$USER $LOCAL_PATH
    sudo chown $USER:$USER $LOCAL_PATH

    sudo chmod 700 $LOCAL_PATH
    echo "${GREEN}Local path created${NC}"
fi

# Update the system
echo "${GREEN}Updating system...${NC}"
sudo dnf update -y
echo "${GREEN}System update completed${NC}"

# Check os-release
if [ -e /etc/os-release ]; then
    # Source the os-release file to get the VERSION_ID
    . /etc/os-release

    # Check if VERSION_ID is set
    if [ -n "$VERSION_ID" ]; then
        # Extract the major version
        OS_VERSION_MAJOR=$(echo "$VERSION_ID" | cut -d'.' -f1)

        # Install EPEL repository
        echo "${GREEN}Installing EPEL repository...${NC}"
        sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-$OS_VERSION_MAJOR.noarch.rpm -y
        echo "${GREEN}EPEL repository installed${NC}"
    else
        echo "${RED}Error: VERSION_ID is not set in /etc/os-release${NC}"
    fi
else
    echo "${NC}Error: /etc/os-release file not found${NC}"
fi

# Install s3fs-fuse
echo "${GREEN}Installing s3fs-fuse...${NC}"
sudo yum install s3fs-fuse -y
# Check the exit code of the yum command
# $? is a special variable that holds the exit code of the last executed command.
if [ $? -eq 0 ]; then
    echo "${GREEN}s3fs-fuse has been successfully installed${NC}"
else
    echo "${RED}Error: Package installation failed"${NC}
    exit
fi

# Prompt user for Customer Secret Key credentials
read -p "${CR}${YELLOW}Enter your Customer Secret Key ID: ${NC}${CR}" KEY_ID
read -p "${CR}${YELLOW}Enter your Customer Secret Key Secret: ${NC}${CR}" KEY_SECRET
echo
# Set API credentials in /etc/passwd-s3fs
PWD_FILE="/etc/passwd-s3fs"
echo "$KEY_ID:$KEY_SECRET" | sudo tee $PWD_FILE
sudo chown $USER:$USER $PWD_FILE
sudo chmod 600 $PWD_FILE
echo "${GREEN}API credentials set${NC}"

# Prompt user for OCI bucket details
read -p "${CR}${YELLOW}Enter your OCI storage namespace:${NC}${CR}" NAMESPACE
read -p "${CR}${YELLOW}Enter your OCI Region ID:${NC}${CR}" OCI_REGION_ID

# Check if the bucket contains only lowercase letters, numbers, dashes, and underscores
while true; do
    read -p "${CR}${YELLOW}Enter your OCI bucket name: ${NC}${CR}" BUCKET

    if [[ ! "$BUCKET" =~ ^[a-z0-9_-]+$ ]]; then
        echo "${RED}Error: BUCKET should contain only lowercase letters, numbers, dashes, and underscores.${NC}${CR}"
    else
        break
    fi
done

# Set OCI Object Storage URL 
URL="https://${NAMESPACE}.compat.objectstorage.${OCI_REGION_ID}.oraclecloud.com"

# Mount OCI bucket using s3fs
echo "${GREEN}Mounting OCI bucket...${NC}"
#s3fs $BUCKET $LOCAL_PATH -o passwd_file=$PWD_FILE -o suid -o url=$URL -o use_path_request_style -o multipart_size=128 -o parallel_count=50 -o multireq_max=100 -o max_background=1000 -o endpoint=$OCI_REGION_ID
s3fs $BUCKET $LOCAL_PATH -o passwd_file=$PWD_FILE -o suid -o url=$URL -o use_path_request_style -o endpoint=$OCI_REGION_ID

if [ $? -eq 0 ]; then
    echo "${GREEN}OCI bucket mounted${NC}${CR}"
    # Get mounted filesystem information
    mounted_info=$(df -h | grep s3fs)
else
    echo "${RED}Error while mounting bucket, please check provided information${NC}"
fi
# FSTAB section
while true; do
    read -p "${CR}${YELLOW}Do you want to mount s3fs share at boot using FSTAB? (yes/no): ${NC}${CR}" answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

    if [ "$answer" = "yes" ]; then
        FSTAB=$"Yes"
        # Get user UID / GID
        id_output=$(id)
        U_ID=$(echo "$id_output" | awk -F'[=(]' '{print $2}')
        G_ID=$(echo "$id_output" | awk -F'[=(]' '{print $4}')
        # Add entry to /etc/fstab for automatic mounting on boot
        echo "${GREEN}Adding entry to /etc/fstab...${NC}"
        echo | sudo tee -a /etc/fstab
        echo "# ${BUCKET} - S3FS mount point"| sudo tee -a /etc/fstab
        #echo "$BUCKET $LOCAL_PATH fuse.s3fs use_path_request_style,passwd_file=$PWD_FILE,url=$URL,endpoint=$OCI_REGION_ID kernel_cache,multipart_size=128,parallel_count=50,multireq_max=100,max_background=1000,_netdev,allow_other,uid=1000,gid=1000 0 0" | sudo tee -a /etc/fstab
        echo "$BUCKET $LOCAL_PATH fuse.s3fs _netdev,allow_other,use_path_request_style,passwd_file=$PWD_FILE,url=$URL,endpoint=$OCI_REGION_ID,uid=$U_ID,gid=$G_ID 0 0" | sudo tee -a /etc/fstab
        echo "${GREEN}Entry added to /etc/fstab${NC}${CR}"
        break
    elif [ "$answer" = "no" ]; then
        FSTAB=$"No"
        break
    else
        echo "${RED}Invalid answer. Please enter 'yes' or 'no' ${NC}${CR}"
    fi
done

# Print summary
echo "${CR}${GREEN}Installation summary:"
echo "Local User: $USER"
echo "Local Path: $LOCAL_PATH"
echo "OCI Bucket: $BUCKET"
echo "OCI URL: $URL"
echo "OCI Key ID: $KEY_ID"
echo "PWD File: $PWD_FILE"
echo "Mount info: $mounted_info"
echo "FSTAB: $FSTAB"
echo
echo "Installation completed successfully ${NC}"
