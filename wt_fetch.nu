#!/usr/bin/env nu

use std

# Age limit before cache will be re-fetched.
const STALE_TIME = 2hr

# Cached, opinionated interface for `wttr.in`.
def main [
    location: string, # Location to check. Ex: 'KCOS' or 'Colorado Springs'.
    cache: path,      # Path to directory to store cache files.
    --all,            # Include all.
    --temp,           # Include temperature output.
    --condition,      # Include condition output.
    --wind,           # Include wind output.
    --moon,           # Include moon phase output.
    --humidity,       # Include relative humidity output.
] {

    mut output = {}

    if ($temp or $all) {
        $output.temp = (get_current_temperature $location $cache)
    }
    if ($condition or $all) {
        $output.condition = (get_current_weather_icon $location $cache)
    }
    if ($wind or $all) {
        $output.wind = (get_current_wind $location $cache)
    }
    if ($moon or $all) {
        $output.moon = (get_current_moon_phase_icon $location $cache)
    }
    if ($humidity or $all) {
        $output.humidity = (get_current_humidity $location $cache)
    }

    $output | to json
}

# Get formatted temperature as string.
export def get_current_temperature [location: string, cache: path] {
    let temp = (fetch_weather $location $cache).wttr.current_condition.temp_F.0
    $"($temp)°F"
}

# Get weather condition icon.
export def get_current_weather_icon [location: string, cache: path] {
    let condition = (fetch_weather $location $cache).wttr.current_condition.weatherDesc.0.0.value
    match_condition_icon $condition
}

# Get formatted wind information as string.
export def get_current_wind [location: string, cache: path] {
    let weather = (fetch_weather $location $cache)
    let direction = (match_direction_icon $weather.wttr.current_condition.winddir16Point.0)
    let speed = $weather.wttr.current_condition.windspeedMiles.0

    $"($direction)($speed)mph"
}

# Get moon phase icon.
export def get_current_moon_phase_icon [location: string, cache: path] {
    let phase = (fetch_weather $location $cache).wttr.weather.astronomy.0.moon_phase.0
    match_moon_phase_icon $phase
}

# Get relative humidity.
export def get_current_humidity [location: string, cache: path] {
    let humidity = (fetch_weather $location $cache).wttr.current_condition.humidity.0
    $"($humidity)%"
}

# Get cache file path as string.
def get_cache_file_path [location: string, cache: path] {
    $"($cache | path expand)/wttr-in_($location).json"
}

# Query `wttr.in` for weather report with location and save to a file.
def build_cache [
    location: string,
    cache: path,
    weather_file?: string, # For testing.
] {
    try {
        std log debug "Building cache"

        let weather = (
            if ($weather_file) == null {
                http get $"https://wttr.in/($location)?format=j1"
            } else {
                open $weather_file
            }
        )

        # If `wttr` is not a record then the called failed on `wttr`s end.
        if (($weather | describe | split row '<' | get 0) != "record") {
            std error "Failed to retrieve weather from `wttr`."
            return
        }

        let now = (date now)

        { modified: $now, wttr: $weather }
        | to json
        | save -f $"(get_cache_file_path $location $cache)"
    } catch {|e|
        std log error $"Failed to build cache with error: ($e)"
    }
}

# Fetcher that will prefer to use cache.
# Will return record of `wttr.in` json response.
def fetch_weather [location: string, cache: path] {

    let cache_file_path = get_cache_file_path $location $cache
    let now = (date now)

    # Only build cache if older than `STALE_TIME` or if doesn't exist.
    if ($cache_file_path | path exists) {
        std log debug $"Cache for ($cache_file_path) already exists"

        let modified = (open $cache_file_path).modified | into datetime

        if ($now > ($modified + $STALE_TIME)) {
            std log debug $"Updating cache: ($cache_file_path)"
            build_cache $location $cache_file_path
        }
    } else {
        std log debug $"Initializing cache ($cache_file_path)"
        build_cache $location $cache
    }

    open $cache_file_path
}

# Match a moon phase (full, etc...) to an icon (🌕, etc...).
def match_moon_phase_icon [phase: string] {
    match ($phase | str replace -a " " "" | str downcase) {
        "newmoon"        => "🌑",
        "waxingcrescent" => "🌒",
        "firstquarter"   => "🌓",
        "waxinggibbous"  => "🌔",
        "full"           => "🌕",
        "waninggibbous"  => "🌖",
        "lastquarter"    => "🌗",
        "waningcrescent" => "🌘",
        _                => $phase
    }
}

# Match a wind direction (SE, etc...) to an icon (↘ etc...).
def match_direction_icon [direction: string] {

    # Reduce 16-point direction to 8-point.
    let eight_point = (
        if (($direction | str length) == 3) {
            $direction | str substring 1..
        } else { $direction }
    )

    match ($eight_point | str replace -a " " "" | str downcase) {
        "s"  => "↓",
        "sw" => "↙",
        "w"  => "←",
        "nw" => "↖",
        "n"  => "↑",
        "ne" => "↗",
        "e"  => "→",
        "se" => "↘",
        _    => "?",
    }
}

# Match a weather condition (cloudy, etc...) to an icon (☁️, etc...).
def match_condition_icon [condition: string] {
    # These come from:
    # https://github.com/chubin/wttr.in/blob/6b050470bcee33d265439b4e6df20e043cc621ad/lib/constants.py#L54
    match ($condition | str replace -a " " "" | str downcase) {
        "cloudy"              => {"☁️"},
        "fog"                 => {"🌫"},
        "heavyrain"           => {"🌧"},
        "heavyshowers"        => {"🌧"},
        "heavysnow"           => {"❄️"},
        "heavysnowshowers"    => {"❄️"},
        "lightrain"           => {"🌦"},
        "lightshowers"        => {"🌦"},
        "lightsleet"          => {"🌧"},
        "lightsleetshowers"   => {"🌧"},
        "lightsnow"           => {"🌨"},
        "lightsnowshowers"    => {"🌨"},
        "partlycloudy"        => {"⛅️"},
        "sunny"               => {"☀️"},
        "thunderyheavyrain"   => {"🌩"},
        "thunderyshowers"     => {"⛈"},
        "thunderysnowshowers" => {"⛈"},
        "verycloudy"          => {"☁️"},
        _                     => {"✨"},
    }
}
# This line is just to fix highlighting ---> "

##
## --- Integration Tests ---
##
## These depend on the contents of `./test/wttr.json`.

use std assert

#[before-all]
def build_test_cache [] {
    let location = "KCOS"
    let cache = "./test"

    let test_cache = (get_cache_file_path $location $cache)

    # Cache doesn't already exist
    assert equal ($test_cache | path exists) false

    build_cache $location $cache "./test/wttr.json"

    # Cache is created
    assert equal ($test_cache | path exists) true
}

#[after-all]
def destroy_test_cache [] {
    let location = "KCOS"
    let cache = "./test"

    let test_cache = (get_cache_file_path $location $cache)

    rm $test_cache

    # Cache is deleted
    assert equal ($test_cache | path exists) false
}

#[test]
def test_get_current_temperature [] {
    let location = "KCOS"
    let cache = "./test"
    let expected = "73°F"
    let result = get_current_temperature $location $cache

    assert equal $result $expected
}

#[test]
def test_get_current_weather_icon [] {
    let location = "KCOS"
    let cache = "./test"

    let expected = "⛅️"
    let result = get_current_weather_icon $location $cache

    assert equal $result $expected
}

#[test]
def test_get_current_wind [] {
    let location = "KCOS"
    let cache = "./test"

    let expected = "↘8mph"
    let result = get_current_wind $location $cache

    assert equal $result $expected
}

#[test]
def test_get_current_moon_phase_icon [] {
    let location = "KCOS"
    let cache = "./test"

    let expected = "🌖"
    let result = get_current_moon_phase_icon $location $cache

    assert equal $result $expected
}

#[test]
def test_get_current_humidity [] {
    let location = "KCOS"
    let cache = "./test"

    let expected = "31%"
    let result = get_current_humidity $location $cache

    assert equal $result $expected
}

##
## --- Unit Tests ---
##

#[test]
def test_get_cache_file_path [] {
    let location = "KCOS"
    let cache = "./test"

    let expected = $"('./' | path expand)/test/wttr-in_($location).json"
    let result = get_cache_file_path $location $cache

    assert equal $result $expected
}

#[test]
def test_moon_phase_match [] {
    let expected = "🌘"
    let result = match_moon_phase_icon "Waning Crescent"

    assert equal $result $expected
}

#[test]
def test_wind_direction_sixteen_point [] {
    let expected = "↗"
    let result = match_direction_icon "ENE"

    assert equal $result $expected
}

#[test]
def test_wind_direction_unknown [] {
    let expected = "?"
    let result = match_direction_icon "North"

    assert equal $result $expected
}

#[test]
def test_wind_direction_match [] {
    let expected = "↖"
    let result = match_direction_icon "NW"

    assert equal $result $expected
}

#[test]
def test_condition_icon_match [] {
    let expected = "❄️"
    let result = match_condition_icon "Heavy Snow Showers"

    assert equal $result $expected
}

#[test]
def test_condition_icon_unknown [] {
    let expected = "✨"
    let result = match_condition_icon "Apocalyptic Winter"

    assert equal $result $expected
}

