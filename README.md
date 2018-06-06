# Blacklight IIIF Search

A plugin that provides IIIF Content Search functionality for [Blacklight](https://github.com/projectblacklight/blacklight)-based applications.

[IIIF Content Search](http://iiif.io/api/search/1.0) is an API specification for facilitating searching the full text of a resource that is described by a IIIF Presentation API manifest.

When installed, the plugin provides an endpoint in your app that will return a JSON response conforming to IIIF Content Search API v. 1.0.

By integrating the URL for this service into your IIIF Presentation manifests, clients/viewers that support the IIIF Content Search API will be able to provide functionality for searching within a resource and displaying results.

## Prerequisites

Currently highly opinionated towards Solr as the back-end search index.

This plugin assumes:
1. You have a working Blacklight application
2. You have items with full text (e.g. scanned books) in your Solr index
3. The OCR text for these items is indexed in Solr
4. Each page has its own Solr record, with the corresponding OCR text in a discrete field 
    * the OCR text field must be indexed
    * if search term highlighting is desired, the OCR text field must be indexed and stored
5. The relationship between page records and their parent book/volume/issue/etc records is indexed in Solr

## Installation

Add Blacklight IIIF Search to your `Gemfile`:

```ruby
gem 'blacklight_iiif_search'
```

Run the install generator which will copy over some initial templates, routes, and configuration:

```bash
$ rails generate blacklight_iiif_search:install
```

After install, you'll probably need to adjust the `iiif_search` configuration settings in your app's `CatalogController`:

Config option | Description 
------------------------ | -------------------------------------------------------------
`full_text_field`        | The Solr field where the OCR text is indexed/stored.
`object_relation_field`  | The Solr field where the parent/child relationship is stored.
`supported_params`       | An array of IIIF Content Search [query parameters](http://iiif.io/api/search/1.0/#query-parameters) supported by the search service. (Note: `motivation`, `date`, and `user` are not currently supported.)

See below for additional customization options.

## Basic Usage

The search service will be available at:
```
http://host:port/catalog/:id/iiif_search
```
There is a `solr_document_iiif_search` route helper that can be called to construct a path or URL to the service in your app. For example:
```ruby
solr_document_iiif_search_url('abcd1234', {q: 'blacklight'})
```
Would return:
```
http://host:port/catalog/abcd1234/iiif_search?q=blacklight
```

## Customization
**Parent/child relationship**

The plugin needs to construct Solr query parameters such that only records that represent children (e.g. pages) of the parent work are returned. The out-of-the-box default is:
```ruby
{is_page_of_s: 'parent_id'}
```
Where `parent_id` is the identifier of the parent object. The above assumes that each page record has an indexed `is_page_of_s` field that enumerates its parent.
 
To customize the construction of the parent/child object relationship Solr parameters (beyond the name of the field, which can be set in the `CatalogController` config), create a local copy of the `BlacklightIiifSearch::IiifSearchBehavior` module in `app/models/concerns/blacklight_iiif_search/iiif_search_behavior.rb` and override the `#object_relation_solr_params` method.

**Default search settings**

A `IiifSearchBuilder` class will be available in your app's `app/models` directory, and can be customized as needed, especially with regards to Solr's highlighting settings.

**URI constructors**

As part of the JSON response, the plugin needs to construct URIs for IIIF Annotation objects representing the search hits, and IIIF Canvas objects corresponding to the pages of the item. 

To customize these URIs (including the addition of word/image coordinates to facilitate hit highlighting in a viewer), create a local copy of the `BlacklightIiifSearch::IiifSearchAnnotationBehavior` module in `app/models/concerns/blacklight_iiif_search/iiif_search_annotation_behavior.rb` and override the appropriate methods.

## Development

After cloning the repository, and running `bundle install`, run `rake ci` from the project's root directory, which will:
1. Generate the test application at `.internal_test_app`
2. Run `Blacklight` and `BlacklightIiifSearch` generators
3. Start Solr and index the sample Solr docs from `spec/fixtures`
    * (Note: The Solr config is created by Blackight's installer, and is generated into `.internal_test_app/solr/conf`.)
4. Run all specs

**Various useful development commands:**

Create the internal test app:
```
$ rake engine_cart:generate
```
Remove the internal test app:
```
$ rake engine_cart:clean
```
Start up Solr:
```
$ solr_wrapper
```
Clean out Solr:
```
$ solr_wrapper clean
```
Index sample documents into Solr (run from `.internal_test_app`):
```
$ RAILS_ENV=test rake blacklight_iiif_search:index:seed
```

## Credits

This project was developed as part of the [Newspapers in Samvera](https://www.imls.gov/grants/awarded/lg-70-17-0043-17) grant. Thanks to the Institute of Museum and Library Services for their support.