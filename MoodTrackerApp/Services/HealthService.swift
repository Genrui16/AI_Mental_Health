import Foundation
import HealthKit

/// 封装 Apple Health 数据交互的服务，支持请求授权和获取数据。
final class HealthService {
    static let shared = HealthService()

    private let healthStore = HKHealthStore()
    private init() {}

    /// 请求读取指定的健康数据类型，目前只读取步数和睡眠分析。
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        // 需要读取的健康数据类型
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            completion(success)
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
}
