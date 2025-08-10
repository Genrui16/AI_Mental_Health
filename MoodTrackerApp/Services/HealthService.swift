import Foundation
import HealthKit

/// 封装 Apple Health 数据交互的服务，支持请求授权和获取数据。
@available(macOS 13.0, *)
@MainActor
final class HealthService {
    static let shared = HealthService()

    private let healthStore = HKHealthStore()
    private init() {}

    /// 请求读取指定的健康数据类型，目前包括步数、睡眠分析和心率。
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }
        // 需要读取的健康数据类型
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            completion(success, error)
        }
    }

    /// 获取当天的步数总和
    func fetchStepCount(completion: @escaping (Double) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        // 获取当天的开始时间
        let startDate = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let count = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            completion(count)
        }
        healthStore.execute(query)
    }

    /// 获取最近 24 小时的睡眠时长，单位：小时
    func fetchSleepAnalysis(completion: @escaping (Double) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(0)
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
            completion(sleepSeconds / 3600)
        }
        healthStore.execute(query)
    }

    /// 获取当天平均心率
    func fetchHeartRate(completion: @escaping (Double) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(0)
            return
        }
        let startDate = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
            let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let value = result?.averageQuantity()?.doubleValue(for: unit) ?? 0
            completion(value)
        }
        healthStore.execute(query)
    }
}
