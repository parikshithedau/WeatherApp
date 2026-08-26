/// Domain service that evaluates the suitability of activities for a daily forecast.
protocol ActivityScoring: Sendable {
    func rankActivities(for day: DailyWeather) -> [ActivityScore]
}

/// A deterministic, side-effect-free implementation of the activity-scoring rules.
struct ActivityScorer: ActivityScoring, Sendable {
    /// Ranks all activities for a day from the best match to the weakest match.
    func rankActivities(for day: DailyWeather) -> [ActivityScore] {
        [
            outdoorSightseeing(for: day),
            indoorSightseeing(for: day),
            surfing(for: day),
            skiing(for: day)
        ]
        .sorted { lhs, rhs in
            lhs.score == rhs.score ? lhs.activity.rawValue < rhs.activity.rawValue : lhs.score > rhs.score
        }
    }

    private func outdoorSightseeing(for day: DailyWeather) -> ActivityScore {
        var score = 100
        var reasons: [ActivityReason] = []

        if (18...26).contains(day.maximumTemperature) {
            reasons.append(.idealTemperature(Int(day.maximumTemperature)))
        } else if (10..<18).contains(day.maximumTemperature) || (26...32).contains(day.maximumTemperature) {
            score -= 20
            reasons.append(.suboptimalTemperature(Int(day.maximumTemperature)))
        } else {
            score -= 50
            reasons.append(.extremeTemperature(Int(day.maximumTemperature)))
        }

        if day.precipitation > 2 {
            score -= 70
            reasons.append(.heavyRain(day.precipitation))
        } else if day.precipitation > 0 {
            score -= 30
            reasons.append(.lightRain(day.precipitation))
        } else {
            reasons.append(.noRain)
        }

        if day.weatherCode >= 95 {
            score -= 50
            reasons.append(.thunderstormRisk)
        }

        return ActivityScore(
            activity: .outdoorSightseeing,
            score: clamp(score),
            reasons: reasons
        )
    }

    private func indoorSightseeing(for day: DailyWeather) -> ActivityScore {
        var score = 20
        var reasons: [ActivityReason] = []

        if day.precipitation > 10 {
            score += 50
            reasons.append(.heavyRainOutside(day.precipitation))
        } else if day.precipitation >= 2 {
            score += 30
            reasons.append(.rainyOutside(day.precipitation))
        }

        if day.weatherCode >= 95 {
            score += 30
            reasons.append(.thunderstormExpected)
        }

        if day.maximumTemperature < 5 || day.maximumTemperature > 32 {
            score += 20
            reasons.append(.uncomfortableOutdoorTemperature)
        }

        if score == 20 {
            reasons.append(.weatherTooNiceToStayInside)
        }

        return ActivityScore(
            activity: .indoorSightseeing,
            score: clamp(score),
            reasons: reasons
        )
    }

    private func surfing(for day: DailyWeather) -> ActivityScore {
        var score = 50
        var reasons: [ActivityReason] = []

        if (15...25).contains(day.maximumWindSpeed) {
            score += 40
            reasons.append(.idealWind(Int(day.maximumWindSpeed)))
        } else if (10..<15).contains(day.maximumWindSpeed) {
            score += 15
            reasons.append(.moderateWind(Int(day.maximumWindSpeed)))
        } else if day.maximumWindSpeed < 10 {
            score -= 40
            reasons.append(.windTooWeak(Int(day.maximumWindSpeed)))
        } else {
            score -= 40
            reasons.append(.windTooStrong(Int(day.maximumWindSpeed)))
        }

        if day.weatherCode >= 95 {
            score -= 60
            reasons.append(.thunderstormSafetyHazard)
        }

        if day.precipitation > 5 {
            score -= 20
            reasons.append(.heavyRain(day.precipitation))
        }

        return ActivityScore(
            activity: .surfing,
            score: clamp(score),
            reasons: reasons
        )
    }

    private func skiing(for day: DailyWeather) -> ActivityScore {
        guard day.snowfall > 0 || day.maximumTemperature <= 2 else {
            return ActivityScore(
                activity: .skiing,
                score: 0,
                reasons: [.noSnowAndTemperature(Int(day.maximumTemperature))]
            )
        }

        var score = 0
        var reasons: [ActivityReason] = []

        if day.snowfall > 0 {
            score += min(Int(day.snowfall * 20), 60)
            reasons.append(.freshSnow(day.snowfall))
        }

        if day.maximumTemperature <= 0 {
            score += 40
            reasons.append(.freezingConditions(Int(day.maximumTemperature)))
        } else if day.maximumTemperature <= 3 {
            score += 15
            reasons.append(.nearFreezing(Int(day.maximumTemperature)))
        }

        return ActivityScore(
            activity: .skiing,
            score: clamp(score),
            reasons: reasons
        )
    }

    private func clamp(_ score: Int) -> Int {
        max(0, min(100, score))
    }
}
