import SwiftUI
import HealthKit

struct stepContentView: View {
    let healthStore = HKHealthStore()
    @State var stepCount: Int = 3456
    @State var caloriesBurned: Int = 0
    @State var selectedTarget: Int = 5000
    
    var targets: [Int] = [5000, 10000, 15000, 20000]
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("")
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color("TopColor"), Color(.white), Color("TopColor")]), startPoint: .topTrailing, endPoint: .bottomLeading))
                Text("Steps")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                    
            }
            .padding(.bottom, 100)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 50)
                    .foregroundColor(.gray)
                
                Circle()
                    .trim(from: 0, to: CGFloat(stepCount) / CGFloat(selectedTarget))
                    .stroke(style: StrokeStyle(lineWidth: 50, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(-90))
                
                Text("\(stepCount)")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .frame(width: 275, height: 275)
            
            VStack {
                HStack {
                    VStack {
                        Image(systemName: "flame.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("\(caloriesBurned) kcal")
                            .font(.largeTitle)
                            .frame(width: 150)
                    }
                    .padding()
                    
                    Spacer()
                        .overlay(Image(systemName: "steps"))
                    
                    VStack(alignment: .trailing) {
                        VStack {
                            Image(systemName: "stopwatch.fill")
                                .font(.largeTitle)
                                .foregroundColor(.green)
                            Text("0 min")
                                .font(.largeTitle)
                                .frame(width: 150)
                        }
                        .padding()
                    }
                }
            }
            .padding()
            
            Text("Select today's step target")
                .font(.headline)
                .padding()
            
            Picker("Step Count Target", selection: $selectedTarget) {
                ForEach(targets, id: \.self) { target in
                    Text("\(target) steps")
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
        }
        .onAppear {
            self.requestAuth()
            self.fetchStepCount()
            self.updateCaloriesBurned() // Call the function to update caloriesBurned
        }
        .padding()
    }
    
    func requestAuth() {
        let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)
        let shareTypes = Set([HKObjectType.workoutType(), HKObjectType.quantityType(forIdentifier: .stepCount)!])
        let readTypes = Set([HKObjectType.workoutType(), HKObjectType.quantityType(forIdentifier: .stepCount)!])
        
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { (success, error) in
            if let error = error {
                print("Not Authorized to use HealthKit ")
            } else if success {
                print("Request Granted")
            }
        }
    }
    
    func fetchStepCount() {
        let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepCount, quantitySamplePredicate: predicate, options: .cumulativeSum) { (query, result, error) in
            if let error = error {
                print("Error fetching records for steps: \(error.localizedDescription) ")
            }
            
            guard let result = result else {
                print("No step count data available for the specific predicate")
                return
            }
            
            if let sum = result.sumQuantity() {
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                self.stepCount = steps
            } else {
                self.stepCount = 0
            }
            
            self.updateCaloriesBurned() // Call the function to update caloriesBurned
        }
        healthStore.execute(query)
    }
    
    func updateCaloriesBurned() {
        let caloriesPerStep = 0.04
        
        let stepsPerCalorie: [Int: Int] = [
            625: 25,
            1250: 50,
            2500: 100,
            5000: 200,
            10000: 400,
            20000: 800,
            40000: 16000
        ]
        
        if let calories = stepsPerCalorie[stepCount] {
            caloriesBurned = calories
        } else {
            caloriesBurned = Int(Double(stepCount) * caloriesPerStep)
        }
    }
}

struct stepContentView_Previews: PreviewProvider {
    static var previews: some View {
        stepContentView()
    }
}
