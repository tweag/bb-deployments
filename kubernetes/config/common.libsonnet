local localKeyPair = {
  files: {
    certificate_path: '/cert/tls.crt',
    private_key_path: '/cert/tls.key',
    refresh_interval: '3600s',
  },
};

local grpcClientWithTLS = function(address) {
  address: address,
  tls: {
    server_certificate_authorities: import 'ca-cert.jsonnet',
    client_key_pair: localKeyPair,
  },
};

local oneListenAddressWithTLS = function(address) [{
  listenAddresses: [address],
  authenticationPolicy: {
    tls_client_certificate: {
      client_certificate_authorities: import 'ca-cert.jsonnet',
      validation_jmespath_expression: '`true`',
      metadata_extraction_jmespath_expression: '`{}`',
    },
  },
  tls: {
    server_key_pair: localKeyPair,
  },
}];

{
  blobstore: {
    contentAddressableStorage: {
      sharding: {
        hashInitialization: 11946695773637837490,
        shards: [
          {
            backend: { grpc: grpcClientWithTLS('storage-0.storage.buildbarn:8981') },
            weight: 1,
          },
          {
            backend: { grpc: grpcClientWithTLS('storage-1.storage.buildbarn:8981') },
            weight: 1,
          },
        ],
      },
    },
    actionCache: {
      completenessChecking: {
        backend: {
          sharding: {
            hashInitialization: 14897363947481274433,
            shards: [
              {
                backend: { grpc: grpcClientWithTLS('storage-0.storage.buildbarn:8981') },
                weight: 1,
              },
              {
                backend: { grpc: grpcClientWithTLS('storage-1.storage.buildbarn:8981') },
                weight: 1,
              },
            ],
          },
        },
        maximumTotalTreeSizeBytes: 64 * 1024 * 1024,
      },
    },
  },
  browserUrl: 'http://bb-browser.example.com:80',
  maximumMessageSizeBytes: 2 * 1024 * 1024,
  global: {
    diagnosticsHttpServer: {
      httpServers: [{
        listenAddresses: [':9980'],
        authenticationPolicy: { allow: {} },
      }],
      enablePrometheus: true,
      enablePprof: true,
      enableActiveSpans: true,
    },
  },
  grpcClientWithTLS: grpcClientWithTLS,
  oneListenAddressWithTLS: oneListenAddressWithTLS,
}
