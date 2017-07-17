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
echo "# VNet's Web Subnet"
echo "################################"

export AZ_WEB_SUBNET_NAME=Web-Subnet
export AZ_WEB_SUBNET_CIDR=10.0.2.0/24

az network vnet subnet create \
   -n                           $AZ_WEB_SUBNET_NAME \
   --address-prefix             $AZ_WEB_SUBNET_CIDR \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \

az network vnet subnet list \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# Public IP "
echo "################################"

export AZ_PUBLIC_IP_NAME=PublicIP
export AZ_PUBLIC_IP_LOC=${AZ_RG_LOC}
export AZ_PUBLIC_IP_DNSNAME=${USER}loadbalancernrp
export AZ_PUBLIC_IP_TIMEOUT=4
export AZ_PUBLIC_IP_ALLOCATION=Static


az network public-ip create \
   -n                           $AZ_PUBLIC_IP_NAME \
   -l                           $AZ_PUBLIC_IP_LOC \
   --allocation-method          $AZ_PUBLIC_IP_ALLOCATION \
   --dns-name                   $AZ_PUBLIC_IP_DNSNAME \
   --idle-timeout               $AZ_PUBLIC_IP_TIMEOUT \
   -g                           $AZ_RG_NAME \



echo ""
################################################################
echo "################################"
echo "# External LB "
echo "################################"

export AZ_ELB_NAME=External-LB
export AZ_ELB_LOC=${AZ_RG_LOC}
export AZ_ELB_BE_NAME=LB-Backend
export AZ_ELB_FE_NAME=LB-Frontend

az network lb create \
   -n                           $AZ_ELB_NAME \
   -l                           $AZ_ELB_LOC \
   --public-ip-address          $AZ_PUBLIC_IP_NAME \
   --frontend-ip-name           $AZ_ELB_FE_NAME \
   --backend-pool-name          $AZ_ELB_BE_NAME \
   -g                           $AZ_RG_NAME \


az network lb list \
   -g                           $AZ_RG_NAME \
   -o                           table \



echo ""
################################################################
echo "################################"
echo "# External LB rule"
echo "################################"

export AZ_ELB_RULE_NAME=HTTP
export AZ_ELB_RULE_PROTOCOL=tcp
export AZ_ELB_RULE_FE_PORT=80
export AZ_ELB_RULE_BE_PORT=${AZ_ELB_RULE_FE_PORT}

az network lb rule create \
   -n                           $AZ_ELB_RULE_NAME \
   -g                           $AZ_RG_NAME \
   --lb-name                    $AZ_ELB_NAME \
   --backend-pool-name          $AZ_ELB_BE_NAME \
   --backend-port               $AZ_ELB_RULE_BE_PORT \
   --frontend-ip-name           $AZ_ELB_FE_NAME \
   --frontend-port              $AZ_ELB_RULE_FE_PORT \
   --protocol                   $AZ_ELB_RULE_PROTOCOL \


az network lb rule list \
   --lb-name                    $AZ_ELB_NAME \
   -g                           $AZ_RG_NAME  \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# External LB inbound NAT rules"
echo "################################"

export AZ_ELB_NAT_RULE_PROTOCOL=tcp

export AZ_ELB_NAT_RULE1_NAME=WebRDP1
export AZ_ELB_NAT_RULE1_FE_PORT=3441
export AZ_ELB_NAT_RULE1_BE_PORT=3389

export AZ_ELB_NAT_RULE2_NAME=WebRDP2
export AZ_ELB_NAT_RULE2_FE_PORT=3442
export AZ_ELB_NAT_RULE2_BE_PORT=3389


az network lb inbound-nat-rule create \
   -n                           $AZ_ELB_NAT_RULE1_NAME \
   --frontend-port              $AZ_ELB_NAT_RULE1_FE_PORT \
   --backend-port               $AZ_ELB_NAT_RULE1_BE_PORT \
   --protocol                   $AZ_ELB_NAT_RULE_PROTOCOL \
   --frontend-ip-name           $AZ_ELB_FE_NAME \
   --lb-name                    $AZ_ELB_NAME \
   -g                           $AZ_RG_NAME \


az network lb inbound-nat-rule create \
   -n                           $AZ_ELB_NAT_RULE2_NAME \
   --frontend-port              $AZ_ELB_NAT_RULE2_FE_PORT \
   --backend-port               $AZ_ELB_NAT_RULE2_BE_PORT \
   --protocol                   $AZ_ELB_NAT_RULE_PROTOCOL \
   --frontend-ip-name           $AZ_ELB_FE_NAME \
   --lb-name                    $AZ_ELB_NAME \
   -g                           $AZ_RG_NAME \


az network lb inbound-nat-rule list \
   --lb-name                    $AZ_ELB_NAME \
   -g                           $AZ_RG_NAME \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# External LB health probes"
echo "################################"

export AZ_ELB_HTTP_PROBE_NAME=HealthProbeHTTP
export AZ_ELB_HTTP_PROBE_INTERVAL=15
export AZ_ELB_HTTP_PROBE_THRESHOLD=2
export AZ_ELB_HTTP_PROBE_PORT=80
export AZ_ELB_HTTP_PROBE_PROTOCOL=http
export AZ_ELB_HTTP_PROBE_PATH="HealthProbe.aspx"


az network lb probe create \
   -n                           $AZ_ELB_HTTP_PROBE_NAME \
   --interval                   $AZ_ELB_HTTP_PROBE_INTERVAL \
   --threshold                  $AZ_ELB_HTTP_PROBE_THRESHOLD \
   --port                       $AZ_ELB_HTTP_PROBE_PORT \
   --protocol                   $AZ_ELB_HTTP_PROBE_PROTOCOL \
   --path                       $AZ_ELB_HTTP_PROBE_PATH \
   --lb-name                    $AZ_ELB_NAME \
   -g                           $AZ_RG_NAME \


# az network lb probe delete \
#    --name                     $AZ_ELB_HTTP_PROBE_NAME \
#    -g                         $AZ_RG_NAME \
#    --lb-name                  $AZ_ELB_NAME \

az network lb probe list \
   -g                           $AZ_RG_NAME \
   --lb-name                    $AZ_ELB_NAME \
   -o                           table \


echo ""
################################################################
echo "################################"
echo "# Web NIC creation"
echo "################################"

export AZ_WEB_NIC1_NAME=lb-nic1-be
export AZ_WEB_NIC2_NAME=lb-nic2-be

az network nic create \
   -n                           $AZ_WEB_NIC1_NAME \
   --lb-inbound-nat-rules       $AZ_ELB_NAT_RULE1_NAME \
   --lb-address-pools           $AZ_ELB_BE_NAME \
   --lb-name                    $AZ_ELB_NAME \
   --subnet                     $AZ_WEB_SUBNET_NAME \
   --vnet-name                  $AZ_VNET_NAME \
   -g                           $AZ_RG_NAME \


az network nic create \
   -n                           $AZ_WEB_NIC2_NAME \
   --lb-inbound-nat-rules       $AZ_ELB_NAT_RULE2_NAME \
   --lb-address-pools           $AZ_ELB_BE_NAME \
   --lb-name                    $AZ_ELB_NAME \
   --subnet                     $AZ_WEB_SUBNET_NAME \
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

export AZ_WEB_VM_AVAILSET_NAME=Web-AvSet
export AZ_WEB_VM_AVAILSET_LOC=${AZ_ELB_LOC}

export AZ_WEB_VM1_LOC=${AZ_WEB_VM_AVAILSET_LOC}
export AZ_WEB_VM1_NAME=Web1
export AZ_WEB_VM1_IMAGE=Win2016Datacenter

export AZ_WEB_VM2_LOC=${AZ_WEB_VM_AVAILSET_LOC}
export AZ_WEB_VM2_NAME=Web2
export AZ_WEB_VM2_IMAGE=Win2016Datacenter
export AZ_WEB_VM_ADMIN_USERNAME="yarek"
export AZ_WEB_VM_ADMIN_PASSWORD="ASDFqwer1234@;:."

az vm availability-set create \
   -n                           $AZ_WEB_VM_AVAILSET_NAME \
   -l                           $AZ_WEB_VM_AVAILSET_LOC \
   -g                           $AZ_RG_NAME \


az vm create \
   -n                           $AZ_WEB_VM1_NAME \
   -l                           $AZ_WEB_VM1_LOC \
   --image                      $AZ_WEB_VM1_IMAGE \
   --availability-set           $AZ_WEB_VM_AVAILSET_NAME \
   --nics                       $AZ_WEB_NIC1_NAME \
   --admin-username             $AZ_WEB_VM_ADMIN_USERNAME \
   --admin-password             $AZ_WEB_VM_ADMIN_PASSWORD \
   -g                           $AZ_RG_NAME \


az vm create \
   -n                           $AZ_WEB_VM2_NAME \
   -l                           $AZ_WEB_VM2_LOC \
   --image                      $AZ_WEB_VM2_IMAGE \
   --availability-set           $AZ_WEB_VM_AVAILSET_NAME \
   --nics                       $AZ_WEB_NIC2_NAME \
   --admin-username             $AZ_WEB_VM_ADMIN_USERNAME \
   --admin-password             $AZ_WEB_VM_ADMIN_PASSWORD \
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
