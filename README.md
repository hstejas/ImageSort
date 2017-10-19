Image Sort
==========

This is perl6 script to sort and **MOVE** images based on the GPS coordinates stored in the exif info. The Images without GPS coordinates are not touched.

The destination will look like `<dest_dir>/[Country]/[City/Village/Town]/` in English. (Germany rather than Deutschland)

It currently uses Open Street Map's API with either nominatim or locationiq.org (key required) support

### Usage :
    ./imagesort.pl6 --src=./srd_dir --dest=./dest_dir --apikey=api_key

### TODO:
- Caching location results
- Sort basd on other exif parameters
