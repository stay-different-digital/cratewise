# ADR-0008: Use a custom local thumbnail cache

## Status

Accepted

## Context

Cratewise must support offline collection and wishlist browsing. Cover images
are part of the user experience, but plugin-managed network caches do not
provide a product-level guarantee that images remain available offline.

The architecture notes listed Cached Network Image as a suggested image package.
The app instead implements a local thumbnail cache with repository and service
layers.

## Decision

Use a custom thumbnail cache backed by local storage and repository contracts.

`ThumbnailCacheService` fetches missing thumbnails, stores local files, and
records metadata through `ThumbnailRepository`. UI widgets prefer local cached
paths when available and degrade to placeholders when images cannot be resolved.

## Consequences

Positive:

- Offline behaviour is controlled by Cratewise rather than by an opaque plugin
  cache.
- Thumbnail metadata can support eviction, retry, and storage-limit policies.
- Collection and wishlist cards can lazily fill missing covers after imports.
- Cache failures can be retried without blocking release detail or list screens.

Negative:

- The app owns more file-system and eviction logic.
- UI widgets need explicit placeholder and error states.
- The cache may not provide all conveniences of a dedicated network image
  widget.

## Follow-up

Only add Cached Network Image if it complements the local cache for remote-only
views. Do not replace the local-first thumbnail cache with a plugin cache.
