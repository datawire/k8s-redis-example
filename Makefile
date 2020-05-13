export EASYRSA = /etc/easy-rsa
export EASYRSA_PKI = $(CURDIR)/pki

generate: redis.yaml redis-config.yaml redis-client.target
apply: redis.yaml redis-config.yaml
	kubectl apply $(addprefix --filename=,$^)
.PHONY: apply

########################################################################
# Server

redis-config.yaml: %: %.gen
	./$< $(filter redis-config/%,$^) > $@
redis-config.yaml: redis-config/redis.conf
redis-config.yaml: redis-config/tls.crt
redis-config.yaml: redis-config/tls.key
redis-config.yaml: redis-config/ca.crt

redis-config/ca.crt: $(EASYRSA_PKI)/ca.crt
	install -m644 $< $@
redis-config/%.crt: $(EASYRSA_PKI)/issued/server-%.crt
	install -m644 $< $@
redis-config/%.key: $(EASYRSA_PKI)/private/server-%.key
	install -m644 $< $@

########################################################################
# Client

redis-client.target: redis-client/tls.crt
redis-client.target: redis-client/tls.key
redis-client.target: redis-client/ca.crt
.PHONY: redis-client.target

redis-client/ca.crt: $(EASYRSA_PKI)/ca.crt
	install -Dm644 $< $@
redis-client/%.crt: $(EASYRSA_PKI)/issued/client-%.crt
	install -Dm644 $< $@
redis-client/%.key: $(EASYRSA_PKI)/private/client-%.key
	install -Dm644 $< $@

########################################################################
# EasyRSA bindings

$(EASYRSA_PKI)/ca.crt: $(EASYRSA)/openssl-easyrsa.cnf
	easyrsa init-pki && easyrsa build-ca
$(EASYRSA_PKI)/reqs/%.req $(EASYRSA_PKI)/private/%.key: $(EASYRSA_PKI)/ca.crt
	easyrsa gen-req $* nopass
$(EASYRSA_PKI)/issued/client-%.crt: $(EASYRSA_PKI)/reqs/client-%.req $(EASYRSA)/x509-types/client
	easyrsa sign-req client client-$*
$(EASYRSA_PKI)/issued/server-%.crt: $(EASYRSA_PKI)/reqs/server-%.req $(EASYRSA)/x509-types/server
	easyrsa sign-req server server-$*


########################################################################

.DELETE_ON_ERROR:
.SECONDARY:
