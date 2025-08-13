#if canImport(HealthKit)
import Foundation
import HealthKit

/// 封装 Apple Health 数据交互的服务，支持请求授权和获取数据。
/// 所有完成回调都会在主线程上执行，便于直接更新 UI。
@available(macOS 13.0, iOS 15.0, *)
@MainActor
final class HealthService {
    static let shared = HealthService()

    private let healthStore = HKHealthStore()
    private init() {}

    /// 当前设备是否支持 HealthKit。
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// 请求读取指定的健康数据类型，目前包括步数、睡眠分析和心率。
    /// - Note: `completion` 回调在主线程中执行。
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                completion(false, nil)
            }
            return
        }
        // 需要读取的健康数据类型
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    /// 获取当天的步数总和
    /// - Note: `completion` 回调在主线程中执行。
    func fetchStepCount(completion: @escaping (Double) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            DispatchQueue.main.async {
                completion(0)
            }
            return
        }
        // 获取当天的开始时间
        let startDate = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let count = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            DispatchQueue.main.async {
                completion(count)
            }
        }
        healthStore.execute(query)
    }

    /// 获取最近 24 小时的睡眠时长，单位：小时
    /// - Note: `completion` 回调在主线程中执行。
    func fetchSleepAnalysis(completion: @escaping (Double) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            DispatchQueue.main.async {
                completion(0)
            }
            return
        }
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, _ in
            var sleepSeconds: Double = 0
            results?.forEach { sample in
                if let sample = sample as? HKCategorySample {
                    sleepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                }
            }
            DispatchQueue.main.async {
                completion(sleepSeconds / 3600)
            }
        }
        healthStore.execute(query)
    }

    /// 获取当天平均心率
    /// - Note: `completion` 回调在主线程中执行。
    func fetchHeartRate(completion: @escaping (Double) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            DispatchQueue.main.async {
                completion(0)
            }
            return
        }
        let startDate = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
            let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let value = result?.averageQuantity()?.doubleValue(for: unit) ?? 0
            DispatchQueue.main.async {
                completion(value)
            }
        }
        healthStore.execute(query)
    }

    /// 获取最近 7 天的每日步数总和
    @available(iOS 15.0, *)
    func fetchDailySteps7D() async throws -> [(Date, Int)] {
        let cal = Calendar.current
        let end = cal.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
        let start = cal.date(byAdding: .day, value: -7, to: end)!
        var results: [(Date, Int)] = []

        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let interval = DateComponents(day: 1)
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: cal.startOfDay(for: start),
            intervalComponents: interval
        )

        return try await withCheckedThrowingContinuation { cont in
            query.initialResultsHandler = { _, coll, err in
                if let err = err {
                    return cont.resume(throwing: err)
                }
                coll?.enumerateStatistics(from: start, to: end) { stats, _ in
                    let date = stats.startDate
                    let value = Int(stats.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                    results.append((date, value))
                }
                cont.resume(returning: results)
            }
            self.healthStore.execute(query)
        }
    }

    /// 获取最近 7 天每日睡眠时长（分钟）
    @available(iOS 15.0, *)
    func fetchSleepMinutes7D() async throws -> [(Date, Int)] {
        let cal = Calendar.current
        let end = cal.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
        let start = cal.date(byAdding: .day, value: -7, to: end)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let asleepVals: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]

        return try await withCheckedThrowingContinuation { cont in
            var bucket: [Date: Int] = [:]
            guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
                return cont.resume(returning: [])
            }
            let q = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, err in
                if let err = err {
                    return cont.resume(throwing: err)
                }
                samples?.compactMap { $0 as? HKCategorySample }.forEach { s in
                    guard asleepVals.contains(s.value) else { return }
                    let day = cal.startOfDay(for: s.startDate)
                    let minutes = Int(s.endDate.timeIntervalSince(s.startDate) / 60)
                    bucket[day, default: 0] += minutes
                }
                let sorted = bucket.keys.sorted().map { ($0, bucket[$0] ?? 0) }
                cont.resume(returning: sorted)
            }
            self.healthStore.execute(q)
        }
    }
}
#endif
