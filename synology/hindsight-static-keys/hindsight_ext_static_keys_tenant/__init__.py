# Vendored from vectorize-io/hindsight @ 4bf49c5 (MIT); keep in sync with the server image.
"""Static-keys tenant extension for the Hindsight API server.

Configure the server to load it with::

    HINDSIGHT_API_TENANT_EXTENSION=hindsight_ext_static_keys_tenant:StaticKeysTenantExtension
"""

from hindsight_ext_static_keys_tenant.extension import StaticKeysTenantExtension

__all__ = ["StaticKeysTenantExtension"]
