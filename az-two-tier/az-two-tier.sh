#! /bin/bash

for i in `env | egrep "^AZ_" | cut -f 1 -d=`; do
    echo "Unsetting $i"
    unset $i;
done

export AZ_VM_ADMIN_USERNAME="yarek"
export AZ_VM_ADMIN_PASSWORD="ASDFqwer1234@;:."

echo ""
################################################################
echo "################################"
echo "# Resource Group"
echo "################################"

export AZ_RG_NAME=twotier
export AZ_RG_LOC=australiaeast

az group create \
   -n                           $AZ_RG_NAME \
   -l                           $AZ_RG_LOC  \

az group list \
   -o                           table \


#az group delete \
#   -n                           $AZ_RG_NAME \


echo ""
################################################################
echo "################################"
echo "# Virtual Network"
echo "################################"

export AZ_VNET_PREFIX=10.1
export AZ_VNET_NAME="${AZ_RG_NAME}-vnet"
export AZ_VNET_CIDR="${AZ_VNET_PREFIX}.0.0/16"

az network vnet create \
   -n                           $AZ_VNET_NAME \
   --address-prefix             $AZ_VNET_CIDR \
   -g                           $AZ_RG_NAME  \


az network vnet list \
   -g                           $AZ_RG_NAME  \
   -o                           table \


echo ""
#################################################################
echo "################################"
echo "# VNet's Web Subnet"
echo "################################"

export AZ_WEB_TIER_NAME=web

export AZ_WEB_SUBNET_NAME="${AZ_VNET_NAME}-${AZ_WEB_TIER_NAME}"
export AZ_WEB_SUBNET_PREFIX="${AZ_VNET_PREFIX}.1"
export AZ_WEB_SUBNET_CIDR="${AZ_WEB_SUBNET_PREFIX}.0/24"

az network vnet subnet create \
   -n                           $AZ_WEB_SUBNET_NAME \
   --address-prefix             $AZ_WEB_SUBNET_CIDR \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \


echo ""
#################################################################
echo "################################"
echo "# VNet's DB Subnet"
echo "################################"

export AZ_DB_TIER_NAME=db

export AZ_DB_SUBNET_NAME="${AZ_VNET_NAME}-${AZ_DB_TIER_NAME}"
export AZ_DB_SUBNET_PREFIX="${AZ_VNET_PREFIX}.2"
export AZ_DB_SUBNET_CIDR="${AZ_DB_SUBNET_PREFIX}.0/24"

az network vnet subnet create \
   -n                           $AZ_DB_SUBNET_NAME \
   --address-prefix             $AZ_DB_SUBNET_CIDR \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \

echo ""
#################################################################
echo "################################"
echo "# Subnets List"
echo "################################"

az network vnet subnet list \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# Web Public IP "
echo "################################"

export AZ_WEB_PUBLIC_IP_NAME="${AZ_WEB_SUBNET_NAME}-pip"
export AZ_WEB_PUBLIC_IP_LOC=${AZ_RG_LOC}
export AZ_WEB_PUBLIC_IP_DNSNAME=`echo "${AZ_VM_ADMIN_USERNAME}${AZ_RG_NAME}" | sed 's/-//g'`
export AZ_WEB_PUBLIC_IP_TIMEOUT=4
export AZ_WEB_PUBLIC_IP_ALLOCATION=Static


az network public-ip create \
   -n                           $AZ_WEB_PUBLIC_IP_NAME \
   -l                           $AZ_WEB_PUBLIC_IP_LOC \
   --allocation-method          $AZ_WEB_PUBLIC_IP_ALLOCATION \
   --dns-name                   $AZ_WEB_PUBLIC_IP_DNSNAME \
   --idle-timeout               $AZ_WEB_PUBLIC_IP_TIMEOUT \
   -g                           $AZ_RG_NAME \



echo ""
################################################################
echo "################################"
echo "# Web LB "
echo "################################"

export AZ_WEB_LB_NAME="${AZ_WEB_SUBNET_NAME}-lb"
export AZ_WEB_LB_LOC=${AZ_RG_LOC}
export AZ_WEB_LB_BE_NAME="${AZ_WEB_LB_NAME}-be"
export AZ_WEB_LB_FE_NAME="${AZ_WEB_LB_NAME}-fe"

az network lb create \
   -n                           $AZ_WEB_LB_NAME \
   -l                           $AZ_WEB_LB_LOC \
   --public-ip-address          $AZ_WEB_PUBLIC_IP_NAME \
   --frontend-ip-name           $AZ_WEB_LB_FE_NAME \
   --backend-pool-name          $AZ_WEB_LB_BE_NAME \
   -g                           $AZ_RG_NAME \


az network lb list \
   -g                           $AZ_RG_NAME \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# Web LB health probe"
echo "################################"

export AZ_WEB_LB_RULE_PROTOCOL=tcp
export AZ_WEB_LB_RULE_FE_PORT=80
export AZ_WEB_LB_RULE_NAME="${AZ_WEB_LB_NAME}-${AZ_WEB_LB_RULE_PROTOCOL}"

export AZ_WEB_LB_RULE_HEALTH_PROBE_NAME="${AZ_WEB_LB_RULE_NAME}-probe-${AZ_WEB_LB_RULE_FE_PORT}"
export AZ_WEB_LB_RULE_HEALTH_PROBE_PATH="HealthProbe.aspx"
export AZ_WEB_LB_RULE_HEALTH_PROBE_PROTOCOL=http
export AZ_WEB_LB_RULE_HEALTH_PROBE_INTERVAL=15
export AZ_WEB_LB_RULE_HEALTH_PROBE_THRESHOLD=2


az network lb probe create \
   -n                           $AZ_WEB_LB_RULE_HEALTH_PROBE_NAME \
   --interval                   $AZ_WEB_LB_RULE_HEALTH_PROBE_INTERVAL \
   --threshold                  $AZ_WEB_LB_RULE_HEALTH_PROBE_THRESHOLD \
   --path                       $AZ_WEB_LB_RULE_HEALTH_PROBE_PATH \
   --protocol                   $AZ_WEB_LB_RULE_HEALTH_PROBE_PROTOCOL \
   --port                       $AZ_WEB_LB_RULE_FE_PORT \
   --lb-name                    $AZ_WEB_LB_NAME \
   -g                           $AZ_RG_NAME \


# az network lb probe delete \
#    --name                     $AZ_WEB_LB_RULE_HEALTH_PROBE_NAME \
#    -g                         $AZ_RG_NAME \
#    --lb-name                  $AZ_WEB_LB_NAME \

az network lb probe list \
   -g                           $AZ_RG_NAME \
   --lb-name                    $AZ_WEB_LB_NAME \
   -o                           table \



echo ""
################################################################
echo "################################"
echo "# Web LB rule"
echo "################################"

export AZ_WEB_LB_RULE_BE_PORT=${AZ_WEB_LB_RULE_FE_PORT}

az network lb rule create \
   -n                           $AZ_WEB_LB_RULE_NAME \
   --backend-port               $AZ_WEB_LB_RULE_BE_PORT \
   --frontend-port              $AZ_WEB_LB_RULE_FE_PORT \
   --protocol                   $AZ_WEB_LB_RULE_PROTOCOL \
   --probe-name                 $AZ_WEB_LB_RULE_HEALTH_PROBE_NAME \
   --backend-pool-name          $AZ_WEB_LB_BE_NAME \
   --frontend-ip-name           $AZ_WEB_LB_FE_NAME \
   --lb-name                    $AZ_WEB_LB_NAME \
   -g                           $AZ_RG_NAME \


az network lb rule list \
   --lb-name                    $AZ_WEB_LB_NAME \
   -g                           $AZ_RG_NAME  \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# Web LB inbound NAT rules"
echo "################################"

export AZ_WEB_LB_NAT_RULE_PROTOCOL=tcp

export AZ_WEB_LB_NAT_RULE1_NAME="${AZ_WEB_LB_NAME}-nat-rdp1"
export AZ_WEB_LB_NAT_RULE1_FE_PORT=3441
export AZ_WEB_LB_NAT_RULE1_BE_PORT=3389

export AZ_WEB_LB_NAT_RULE2_NAME="${AZ_WEB_LB_NAME}-nat-rdp2"
export AZ_WEB_LB_NAT_RULE2_FE_PORT=3442
export AZ_WEB_LB_NAT_RULE2_BE_PORT=3389

az network lb inbound-nat-rule create \
   -n                           $AZ_WEB_LB_NAT_RULE1_NAME \
   --frontend-port              $AZ_WEB_LB_NAT_RULE1_FE_PORT \
   --backend-port               $AZ_WEB_LB_NAT_RULE1_BE_PORT \
   --protocol                   $AZ_WEB_LB_NAT_RULE_PROTOCOL \
   --frontend-ip-name           $AZ_WEB_LB_FE_NAME \
   --lb-name                    $AZ_WEB_LB_NAME \
   -g                           $AZ_RG_NAME \


az network lb inbound-nat-rule create \
   -n                           $AZ_WEB_LB_NAT_RULE2_NAME \
   --frontend-port              $AZ_WEB_LB_NAT_RULE2_FE_PORT \
   --backend-port               $AZ_WEB_LB_NAT_RULE2_BE_PORT \
   --protocol                   $AZ_WEB_LB_NAT_RULE_PROTOCOL \
   --frontend-ip-name           $AZ_WEB_LB_FE_NAME \
   --lb-name                    $AZ_WEB_LB_NAME \
   -g                           $AZ_RG_NAME \


# export AZ_WEB_LB_NAT_RULE3_NAME="${AZ_WEB_LB_NAME}-nat-rdp3"
# export AZ_WEB_LB_NAT_RULE3_FE_PORT=3445
# export AZ_WEB_LB_NAT_RULE3_BE_PORT=3389

# export AZ_WEB_LB_NAT_RULE4_NAME="${AZ_WEB_LB_NAME}-nat-rdp4"
# export AZ_WEB_LB_NAT_RULE4_FE_PORT=3446
# export AZ_WEB_LB_NAT_RULE4_BE_PORT=3389


# az network lb inbound-nat-rule create \
#    -n                           $AZ_WEB_LB_NAT_RULE3_NAME \
#    --frontend-port              $AZ_WEB_LB_NAT_RULE3_FE_PORT \
#    --backend-port               $AZ_WEB_LB_NAT_RULE3_BE_PORT \
#    --protocol                   $AZ_WEB_LB_NAT_RULE_PROTOCOL \
#    --frontend-ip-name           $AZ_WEB_LB_FE_NAME \
#    --lb-name                    $AZ_WEB_LB_NAME \
#    -g                           $AZ_RG_NAME \


# az network lb inbound-nat-rule create \
#    -n                           $AZ_WEB_LB_NAT_RULE4_NAME \
#    --frontend-port              $AZ_WEB_LB_NAT_RULE4_FE_PORT \
#    --backend-port               $AZ_WEB_LB_NAT_RULE4_BE_PORT \
#    --protocol                   $AZ_WEB_LB_NAT_RULE_PROTOCOL \
#    --frontend-ip-name           $AZ_WEB_LB_FE_NAME \
#    --lb-name                    $AZ_WEB_LB_NAME \
#    -g                           $AZ_RG_NAME \


az network lb inbound-nat-rule list \
   --lb-name                    $AZ_WEB_LB_NAME \
   -g                           $AZ_RG_NAME \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# DB LB"
echo "################################"

export AZ_DB_LB_NAME="${AZ_DB_SUBNET_NAME}-lb"
export AZ_DB_LB_LOC=${AZ_RG_LOC}
export AZ_DB_LB_PRIVATE_IP="${AZ_DB_SUBNET_PREFIX}.5"
export AZ_DB_LB_BE_NAME="${AZ_DB_LB_NAME}-be"
export AZ_DB_LB_FE_NAME="${AZ_DB_LB_NAME}-fe"

az network lb create \
   -n                           $AZ_DB_LB_NAME \
   -l                           $AZ_DB_LB_LOC \
   --private-ip-address         $AZ_DB_LB_PRIVATE_IP \
   --frontend-ip-name           $AZ_DB_LB_FE_NAME \
   --backend-pool-name          $AZ_DB_LB_BE_NAME \
   --subnet                     $AZ_DB_SUBNET_NAME \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \


az network lb list \
   -g                           $AZ_RG_NAME \
   -o                           table \



echo ""
################################################################
echo "################################"
echo "# DB LB health probe"
echo "################################"

export AZ_DB_LB_RULE_PROTOCOL=tcp
export AZ_DB_LB_RULE_FE_PORT=1433
export AZ_DB_LB_RULE_NAME="${AZ_DB_LB_NAME}-${AZ_DB_LB_RULE_PROTOCOL}"

export AZ_DB_LB_RULE_HEALTH_PROBE_NAME="${AZ_DB_LB_RULE_NAME}-probe-${AZ_DB_LB_RULE_FE_PORT}"
export AZ_DB_LB_RULE_HEALTH_PROBE_PROTOCOL=tcp
export AZ_DB_LB_RULE_HEALTH_PROBE_INTERVAL=15
export AZ_DB_LB_RULE_HEALTH_PROBE_THRESHOLD=2


az network lb probe create \
   -n                           $AZ_DB_LB_RULE_HEALTH_PROBE_NAME \
   --interval                   $AZ_DB_LB_RULE_HEALTH_PROBE_INTERVAL \
   --threshold                  $AZ_DB_LB_RULE_HEALTH_PROBE_THRESHOLD \
   --protocol                   $AZ_DB_LB_RULE_HEALTH_PROBE_PROTOCOL \
   --port                       $AZ_DB_LB_RULE_FE_PORT \
   --lb-name                    $AZ_DB_LB_NAME \
   -g                           $AZ_RG_NAME \


# az network lb probe delete \
#    --name                     $AZ_DB_LB_RULE_HEALTH_PROBE_NAME \
#    -g                         $AZ_RG_NAME \
#    --lb-name                  $AZ_DB_LB_NAME \


az network lb probe list \
   -g                           $AZ_RG_NAME \
   --lb-name                    $AZ_DB_LB_NAME \
   -o                           table \




echo ""
################################################################
echo "################################"
echo "# DB LB rule"
echo "################################"

export AZ_DB_LB_RULE_BE_PORT=${AZ_DB_LB_RULE_FE_PORT}

az network lb rule create \
   -n                           $AZ_DB_LB_RULE_NAME \
   --backend-port               $AZ_DB_LB_RULE_BE_PORT \
   --frontend-port              $AZ_DB_LB_RULE_FE_PORT \
   --protocol                   $AZ_DB_LB_RULE_PROTOCOL \
   --probe-name                 $AZ_DB_LB_RULE_HEALTH_PROBE_NAME \
   --backend-pool-name          $AZ_DB_LB_BE_NAME \
   --frontend-ip-name           $AZ_DB_LB_FE_NAME \
   --lb-name                    $AZ_DB_LB_NAME \
   -g                           $AZ_RG_NAME \


az network lb rule list \
   --lb-name                    $AZ_DB_LB_NAME \
   -g                           $AZ_RG_NAME  \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# DB LB inbound NAT rules"
echo "################################"

export AZ_DB_LB_NAT_RULE_PROTOCOL=tcp

export AZ_DB_LB_NAT_RULE1_NAME="${AZ_DB_LB_NAME}-nat-rdp1"
export AZ_DB_LB_NAT_RULE1_FE_PORT=3443
export AZ_DB_LB_NAT_RULE1_BE_PORT=3389

export AZ_DB_LB_NAT_RULE2_NAME="${AZ_DB_LB_NAME}-nat-rdp2"
export AZ_DB_LB_NAT_RULE2_FE_PORT=3444
export AZ_DB_LB_NAT_RULE2_BE_PORT=3389


az network lb inbound-nat-rule create \
   -n                           $AZ_DB_LB_NAT_RULE1_NAME \
   --frontend-port              $AZ_DB_LB_NAT_RULE1_FE_PORT \
   --backend-port               $AZ_DB_LB_NAT_RULE1_BE_PORT \
   --protocol                   $AZ_DB_LB_NAT_RULE_PROTOCOL \
   --frontend-ip-name           $AZ_DB_LB_FE_NAME \
   --lb-name                    $AZ_DB_LB_NAME \
   -g                           $AZ_RG_NAME \


az network lb inbound-nat-rule create \
   -n                           $AZ_DB_LB_NAT_RULE2_NAME \
   --frontend-port              $AZ_DB_LB_NAT_RULE2_FE_PORT \
   --backend-port               $AZ_DB_LB_NAT_RULE2_BE_PORT \
   --protocol                   $AZ_DB_LB_NAT_RULE_PROTOCOL \
   --frontend-ip-name           $AZ_DB_LB_FE_NAME \
   --lb-name                    $AZ_DB_LB_NAME \
   -g                           $AZ_RG_NAME \


az network lb inbound-nat-rule list \
   --lb-name                    $AZ_DB_LB_NAME \
   -g                           $AZ_RG_NAME \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# Web NIC creation"
echo "################################"

export AZ_WEB_NIC1_NAME="${AZ_WEB_SUBNET_NAME}-1-nic"
export AZ_WEB_NIC2_NAME="${AZ_WEB_SUBNET_NAME}-2-nic"

az network nic create \
   -n                           $AZ_WEB_NIC1_NAME \
   --lb-inbound-nat-rules       $AZ_WEB_LB_NAT_RULE1_NAME \
   --lb-address-pools           $AZ_WEB_LB_BE_NAME \
   --lb-name                    $AZ_WEB_LB_NAME \
   --subnet                     $AZ_WEB_SUBNET_NAME \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \


az network nic create \
   -n                           $AZ_WEB_NIC2_NAME \
   --lb-inbound-nat-rules       $AZ_WEB_LB_NAT_RULE2_NAME \
   --lb-address-pools           $AZ_WEB_LB_BE_NAME \
   --lb-name                    $AZ_WEB_LB_NAME \
   --subnet                     $AZ_WEB_SUBNET_NAME \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \


az network nic list \
   -g                           $AZ_RG_NAME \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# DB NIC creation"
echo "################################"

export AZ_DB_NIC1_NAME="${AZ_DB_SUBNET_NAME}-1-nic"
export AZ_DB_NIC2_NAME="${AZ_DB_SUBNET_NAME}-2-nic"

az network nic create \
   -n                           $AZ_DB_NIC1_NAME \
   --lb-inbound-nat-rules       $AZ_DB_LB_NAT_RULE1_NAME \
   --lb-address-pools           $AZ_DB_LB_BE_NAME \
   --lb-name                    $AZ_DB_LB_NAME \
   --subnet                     $AZ_DB_SUBNET_NAME \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \


az network nic create \
   -n                           $AZ_DB_NIC2_NAME \
   --lb-inbound-nat-rules       $AZ_DB_LB_NAT_RULE2_NAME \
   --lb-address-pools           $AZ_DB_LB_BE_NAME \
   --lb-name                    $AZ_DB_LB_NAME \
   --subnet                     $AZ_DB_SUBNET_NAME \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \


az network nic list \
   -g                           $AZ_RG_NAME \
   -o                           table \



echo ""
################################################################
echo "################################"
echo "# Web VMs with NICs"
echo "################################"

export AZ_WEB_VM_PREFIX="vm-${AZ_WEB_TIER_NAME}"

export AZ_WEB_VM_AVAILSET_NAME="${AZ_WEB_VM_PREFIX}-as"
export AZ_WEB_VM_AVAILSET_LOC=${AZ_WEB_LB_LOC}

export AZ_WEB_VM1_NAME="${AZ_WEB_VM_PREFIX}-1"
export AZ_WEB_VM2_NAME="${AZ_WEB_VM_PREFIX}-2"

export AZ_WEB_VM1_DISK_NAME="${AZ_WEB_VM1_NAME}-disk"
export AZ_WEB_VM2_DISK_NAME="${AZ_WEB_VM2_NAME}-disk"

export AZ_WEB_VM_LOC=${AZ_WEB_VM_AVAILSET_LOC}
export AZ_WEB_VM_IMAGE=Win2016Datacenter

az vm availability-set create \
   -n                           $AZ_WEB_VM_AVAILSET_NAME \
   -l                           $AZ_WEB_VM_AVAILSET_LOC \
   -g                           $AZ_RG_NAME \


az vm availability-set list \
   -g                           $AZ_RG_NAME \
   -o                           table \


az vm create \
   -n                           $AZ_WEB_VM1_NAME \
   --os-disk-name               $AZ_WEB_VM1_DISK_NAME \
   -l                           $AZ_WEB_VM_LOC \
   --image                      $AZ_WEB_VM_IMAGE \
   --availability-set           $AZ_WEB_VM_AVAILSET_NAME \
   --nics                       $AZ_WEB_NIC1_NAME \
   --admin-username             $AZ_VM_ADMIN_USERNAME \
   --admin-password             $AZ_VM_ADMIN_PASSWORD \
   -g                           $AZ_RG_NAME \


az vm create \
   -n                           $AZ_WEB_VM2_NAME \
   --os-disk-name               $AZ_WEB_VM2_DISK_NAME \
   -l                           $AZ_WEB_VM_LOC \
   --image                      $AZ_WEB_VM_IMAGE \
   --availability-set           $AZ_WEB_VM_AVAILSET_NAME \
   --nics                       $AZ_WEB_NIC2_NAME \
   --admin-username             $AZ_VM_ADMIN_USERNAME \
   --admin-password             $AZ_VM_ADMIN_PASSWORD \
   -g                           $AZ_RG_NAME \


az vm list \
   -g                           $AZ_RG_NAME \
   -o                           table \

# az vm deallocate \
#    -n                           $AZ_WEB_VM1_NAME \
#    -g                           $AZ_RG_NAME \


# az vm deallocate \
#    -n                           $AZ_WEB_VM2_NAME \
#    -g                           $AZ_RG_NAME \



echo ""
################################################################
echo "################################"
echo "# DB VMs with NICs"
echo "################################"

export AZ_DB_VM_PREFIX="vm-${AZ_DB_TIER_NAME}"

export AZ_DB_VM_AVAILSET_NAME="${AZ_DB_VM_PREFIX}-as"
export AZ_DB_VM_AVAILSET_LOC=${AZ_DB_LB_LOC}

export AZ_DB_VM1_NAME="${AZ_DB_VM_PREFIX}-1"
export AZ_DB_VM2_NAME="${AZ_DB_VM_PREFIX}-2"

export AZ_DB_VM1_DISK_NAME="${AZ_DB_VM1_NAME}-disk"
export AZ_DB_VM2_DISK_NAME="${AZ_DB_VM2_NAME}-disk"

export AZ_DB_VM_LOC=${AZ_DB_VM_AVAILSET_LOC}
export AZ_DB_VM_IMAGE=Win2016Datacenter

az vm availability-set create \
   -n                           $AZ_DB_VM_AVAILSET_NAME \
   -l                           $AZ_DB_VM_AVAILSET_LOC \
   -g                           $AZ_RG_NAME \


az vm availability-set list \
   -g                           $AZ_RG_NAME \
   -o                           table \


az vm create \
   -n                           $AZ_DB_VM1_NAME \
   --os-disk-name               $AZ_DB_VM1_DISK_NAME \
   -l                           $AZ_DB_VM_LOC \
   --image                      $AZ_DB_VM_IMAGE \
   --availability-set           $AZ_DB_VM_AVAILSET_NAME \
   --nics                       $AZ_DB_NIC1_NAME \
   --admin-username             $AZ_VM_ADMIN_USERNAME \
   --admin-password             $AZ_VM_ADMIN_PASSWORD \
   -g                           $AZ_RG_NAME \


az vm create \
   -n                           $AZ_DB_VM2_NAME \
   --os-disk-name               $AZ_DB_VM2_DISK_NAME \
   -l                           $AZ_DB_VM_LOC \
   --image                      $AZ_DB_VM_IMAGE \
   --availability-set           $AZ_DB_VM_AVAILSET_NAME \
   --nics                       $AZ_DB_NIC2_NAME \
   --admin-username             $AZ_VM_ADMIN_USERNAME \
   --admin-password             $AZ_VM_ADMIN_PASSWORD \
   -g                           $AZ_RG_NAME \


az vm list \
   -g                           $AZ_RG_NAME \
   -o                           table \

# az vm deallocate \
#    -n                           $AZ_DB_VM1_NAME \
#    -g                           $AZ_RG_NAME \


# az vm deallocate \
#    -n                           $AZ_DB_VM2_NAME \
#    -g                           $AZ_RG_NAME \

