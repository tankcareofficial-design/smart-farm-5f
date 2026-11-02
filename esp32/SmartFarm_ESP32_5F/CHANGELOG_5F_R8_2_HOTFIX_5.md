# Smart Farm 5F R8.2 HOTFIX 5

## Fixed
- Corrected the soil-sensor disable logic. `SOIL_SENSOR_ADC_PIN` is a C++ `constexpr`; preprocessor `#if` checks treated it as an undefined macro and still compiled the ADC path.
- Soil moisture now remains `null` while no real sensor is installed.
- No floating GPIO reading can be presented as real soil moisture.

## Compatibility
- Protocol, API, relay count and Flutter models are unchanged.
