#! /bin/bash

for i in `env | egrep "^AZ_" | cut -f 1 -d=`; do
    echo "Unsetting $i"
    unset $i;
done

echo ""
################################################################
echo "################################"
echo "# Resource Group"
echo "################################"

export AZ_RG_NAME=NRP-RG
export AZ_RG_LOC=australiaeast

az group create \
   -n                           $AZ_RG_NAME \
   -l                           $AZ_RG_LOC  \

az group list \
   -o                           table \

echo ""
################################################################
echo "################################"
echo "# Virtual Network"
echo "################################"

export AZ_VNET_NAME=NRPVnet
export AZ_VNET_CIDR=10.0.0.0/16

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
echo "# VNet's DB Subnet"
echo "################################"

export AZ_DB_SUBNET_NAME=DB-Subnet
export AZ_DB_SUBNET_CIDR=10.0.2.0/24

az network vnet subnet create \
   -n                           $AZ_DB_SUBNET_NAME \
   --address-prefix             $AZ_DB_SUBNET_CIDR \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \

az network vnet subnet list \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# Internal LB"
echo "################################"

export AZ_ILB_NAME=Internal-LB
export AZ_ILB_LOC=${AZ_RG_LOC}
export AZ_ILB_PRIVATE_IP=10.0.2.5
export AZ_ILB_BE_NAME=LB-Backend
export AZ_ILB_FE_NAME=LB-Frontend

az network lb create \
   -n                           $AZ_ILB_NAME \
   -l                           $AZ_ILB_LOC \
   --private-ip-address         $AZ_ILB_PRIVATE_IP \
   --frontend-ip-name           $AZ_ILB_FE_NAME \
   --backend-pool-name          $AZ_ILB_BE_NAME \
   --subnet                     $AZ_DB_SUBNET_NAME \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \


az network lb list \
   -g                           $AZ_RG_NAME \
   -o                           table \



echo ""
################################################################
echo "################################"
echo "# Internal LB rule"
echo "################################"

export AZ_ILB_RULE_NAME=HTTP
export AZ_ILB_RULE_PROTOCOL=tcp
export AZ_ILB_RULE_FE_PORT=80
export AZ_ILB_RULE_BE_PORT=${AZ_ILB_RULE_FE_PORT}

az network lb rule create \
   -n                           $AZ_ILB_RULE_NAME \
   -g                           $AZ_RG_NAME \
   --lb-name                    $AZ_ILB_NAME \
   --backend-port               $AZ_ILB_RULE_BE_PORT \
   --backend-pool-name          $AZ_ILB_BE_NAME \
   --frontend-ip-name           $AZ_ILB_FE_NAME \
   --frontend-port              $AZ_ILB_RULE_FE_PORT \
   --protocol                   $AZ_ILB_RULE_PROTOCOL \


az network lb rule list \
   --lb-name                    $AZ_ILB_NAME \
   -g                           $AZ_RG_NAME  \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# Internal LB inbound NAT rules"
echo "################################"

export AZ_ILB_NAT_RULE_PROTOCOL=tcp

export AZ_ILB_NAT_RULE1_NAME=DBRDP1
export AZ_ILB_NAT_RULE1_FE_PORT=3443
export AZ_ILB_NAT_RULE1_BE_PORT=3389

export AZ_ILB_NAT_RULE2_NAME=DBRDP2
export AZ_ILB_NAT_RULE2_FE_PORT=3444
export AZ_ILB_NAT_RULE2_BE_PORT=3389


az network lb inbound-nat-rule create \
   -n                           $AZ_ILB_NAT_RULE1_NAME \
   --frontend-port              $AZ_ILB_NAT_RULE1_FE_PORT \
   --backend-port               $AZ_ILB_NAT_RULE1_BE_PORT \
   --protocol                   $AZ_ILB_NAT_RULE_PROTOCOL \
   --frontend-ip-name           $AZ_ILB_FE_NAME \
   --lb-name                    $AZ_ILB_NAME \
   -g                           $AZ_RG_NAME \


az network lb inbound-nat-rule create \
   -n                           $AZ_ILB_NAT_RULE2_NAME \
   --frontend-port              $AZ_ILB_NAT_RULE2_FE_PORT \
   --backend-port               $AZ_ILB_NAT_RULE2_BE_PORT \
   --protocol                   $AZ_ILB_NAT_RULE_PROTOCOL \
   --frontend-ip-name           $AZ_ILB_FE_NAME \
   --lb-name                    $AZ_ILB_NAME \
   -g                           $AZ_RG_NAME \


az network lb inbound-nat-rule list \
   --lb-name                    $AZ_ILB_NAME \
   -g                           $AZ_RG_NAME \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# Internal LB health porobe rule"
echo "################################"

export AZ_ILB_TCP_PROBE_NAME=HealthProbeTCP
export AZ_ILB_TCP_PROBE_INTERVAL=15
export AZ_ILB_TCP_PROBE_THRESHOLD=2
export AZ_ILB_TCP_PROBE_PORT=80
export AZ_ILB_TCP_PROBE_PROTOCOL=tcp


az network lb probe create \
   -n                           $AZ_ILB_TCP_PROBE_NAME \
   --interval                   $AZ_ILB_TCP_PROBE_INTERVAL \
   --threshold                  $AZ_ILB_TCP_PROBE_THRESHOLD \
   --port                       $AZ_ILB_TCP_PROBE_PORT \
   --protocol                   $AZ_ILB_TCP_PROBE_PROTOCOL \
   --lb-name                    $AZ_ILB_NAME \
   -g                           $AZ_RG_NAME \


# az network lb probe delete \
#    --name                     $AZ_ILB_TCP_PROBE_NAME \
#    -g                         $AZ_RG_NAME \
#    --lb-name                  $AZ_ILB_NAME \


az network lb probe list \
   -g                           $AZ_RG_NAME \
   --lb-name                    $AZ_ILB_NAME \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# DB NIC creation"
echo "################################"

export AZ_DB_NIC1_NAME=lb-nic1-be
export AZ_DB_NIC2_NAME=lb-nic2-be

az network nic create \
   -n                           $AZ_DB_NIC1_NAME \
   --lb-inbound-nat-rules       $AZ_ILB_NAT_RULE1_NAME \
   --lb-address-pools           $AZ_ILB_BE_NAME \
   --lb-name                    $AZ_ILB_NAME \
   --subnet                     $AZ_DB_SUBNET_NAME \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \


az network nic create \
   -n                           $AZ_DB_NIC2_NAME \
   --lb-inbound-nat-rules       $AZ_ILB_NAT_RULE2_NAME \
   --lb-address-pools           $AZ_ILB_BE_NAME \
   --lb-name                    $AZ_ILB_NAME \
   --subnet                     $AZ_DB_SUBNET_NAME \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \


az network nic list \
   -g                           $AZ_RG_NAME \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# DB VMs with NICs"
echo "################################"

export AZ_DB_VM_AVAILSET_NAME=DB-AvSet
export AZ_DB_VM_AVAILSET_LOC=${AZ_ILB_LOC}

export AZ_DB_VM1_LOC=${AZ_DB_VM_AVAILSET_LOC}
export AZ_DB_VM1_NAME=DB1
export AZ_DB_VM1_IMAGE=Win2016Datacenter

export AZ_DB_VM2_LOC=${AZ_DB_VM_AVAILSET_LOC}
export AZ_DB_VM2_NAME=DB2
export AZ_DB_VM2_IMAGE=Win2016Datacenter
export AZ_DB_VM_ADMIN_USERNAME="yarek"
export AZ_DB_VM_ADMIN_PASSWORD="ASDFqwer1234@;:."

az vm availability-set create \
   -n                           $AZ_DB_VM_AVAILSET_NAME \
   -l                           $AZ_DB_VM_AVAILSET_LOC \
   -g                           $AZ_RG_NAME \


az vm create \
   -n                           $AZ_DB_VM1_NAME \
   -l                           $AZ_DB_VM1_LOC \
   --image                      $AZ_DB_VM1_IMAGE \
   --availability-set           $AZ_DB_VM_AVAILSET_NAME \
   --nics                       $AZ_DB_NIC1_NAME \
   --admin-username             $AZ_DB_VM_ADMIN_USERNAME \
   --admin-password             $AZ_DB_VM_ADMIN_PASSWORD \
   -g                           $AZ_RG_NAME \


az vm create \
   -n                           $AZ_DB_VM2_NAME \
   -l                           $AZ_DB_VM2_LOC \
   --image                      $AZ_DB_VM2_IMAGE \
   --availability-set           $AZ_DB_VM_AVAILSET_NAME \
   --nics                       $AZ_DB_NIC2_NAME \
   --admin-username             $AZ_DB_VM_ADMIN_USERNAME \
   --admin-password             $AZ_DB_VM_ADMIN_PASSWORD \
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
