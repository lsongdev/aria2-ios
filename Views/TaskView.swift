//
//  TaskView.swift
//  Aria2
//
//  Created by Lsong on 7/26/23.
//

import SwiftUI

func getTitle(task: TaskObject) -> String {
    let path = task.files?.first?.path ?? ""
    let link = task.files?.first?.uris.first?.uri ?? ""
    let title = (path == "" ? link : path).split(separator: "/").last ?? ""
    return String(title)
}

struct TaskListView: View {
    var rpc: Aria2API
    @State private var showingAddTask = false
    @State private var tasks = [TaskObject]()
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if tasks.isEmpty {
            VStack (alignment: .center) {
                Spacer()
                Text("There's nothing.")
                    .font(.largeTitle)
                    .bold()
                Button(action: {
                    showingAddTask = true
                }) {
                    Text("Add New Task")
                }
                .padding(10)
                .foregroundColor(.white)
                .background(Color.accentColor)
                .cornerRadius(22)
            }
            .padding()
        }
        List {
            ForEach(tasks) { task in
                NavigationLink(destination: TaskDetailView(rpc: rpc, task: task)){
                    TaskView(task: task, rpc: rpc)
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationTitle("Downloads")
        .navigationBarItems(
            trailing:Button(action: {
                showingAddTask = true
            }) {
                Image(systemName: "plus")
            }
        )
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(isPresented: $showingAddTask, rpc: rpc)
        }
        .onAppear() {
            Task{
                await loadData()
            }
            timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        }
        .onReceive(timer) { _ in
            Task {
                await loadData()
            }
        }
        .onDisappear() {
            timer.upstream.connect().cancel()
        }
    }
    
    func loadData() async {
        var arr = [TaskObject]()
        let stats = try! await rpc.getGlobalStat()
        if let numActive = Int(stats.numActive), numActive > 0 {
            let results = try! await rpc.tellActive()
            for result in results {
                arr.append(result)
            }
        }
        if let numWaiting = Int(stats.numWaiting), numWaiting > 0 {
            let results = try! await rpc.tellWaiting()
            for result in results {
                arr.append(result)
            }
        }
        if let numStopped = Int(stats.numStopped), numStopped > 0 {
            let results = try! await rpc.tellStopped()
            for result in results {
                arr.append(result)
            }
        }
        tasks = arr
    }
}

struct TaskView: View {
    var task: TaskObject
    var rpc: Aria2API
    
    var body: some View {
        
        HStack(){
            ZStack (alignment: .bottomTrailing) {
                Image(systemName: "doc.text.fill")
                    .resizable()
                    .frame(width: 32, height: 42)
                    .padding(5)
                    .foregroundColor(Color.accentColor)
                
                let (icon, color) = getIconAndColor(status: task.status)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 25, height: 25)
                    .background(color)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
            VStack(alignment: HorizontalAlignment.leading){
                let path = task.files?.first?.path ?? ""
                let link = task.files?.first?.uris.first?.uri ?? ""
                Text((path == "" ? link : path).split(separator: "/").last ?? "")
                let completedLength = Double(task.completedLength) ?? 0
                let totalLength = Double(task.totalLength) ?? 0
                let completedLengthMB = completedLength / 1024.0 / 1024.0
                let totalLengthMB = totalLength / 1024.0 / 1024.0
                let progressPercent = totalLengthMB > 0 ? (completedLengthMB / totalLengthMB) * 100 : 0.0
                Text(String(format: "%.1fMB of %.1fMB (%.2f%%)", completedLengthMB, totalLengthMB, progressPercent))
                ProgressBar(value: completedLength / totalLength)
            }
            Button(action: {
                Task{
                    if task.status == "active" {
                        try? await rpc.pause(gid: task.gid)
                    } else {
                        try? await rpc.resume(gid: task.gid)
                    }
                }
            }) {
                Image(systemName: task.status == "active" ? "pause.fill" : "play.fill")
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    func getIconAndColor(status: String) -> (String, Color) {
        var icon = ""
        var color = Color.white
        if status == "active" {
            icon = "play.circle.fill"
            color = Color.purple
        }
        if status == "paused" {
            icon = "pause.circle.fill"
            color = Color.orange
        }
        if status == "error" {
            icon = "xmark.circle.fill"
            color = Color.red
        }
        if status == "complete" {
            icon = "checkmark.circle.fill"
            color = Color.green
        }
        return (icon, color)
    }
}

struct TaskDetailView: View {
    var rpc: Aria2API
    @State var task: TaskObject
    
    var body: some View {
        
        List{
            Text(task.bitfield ?? "")
            Section("Basic"){
                HStack{
                    Text("Name")
                    Spacer()
                    Text(getTitle(task: task))
                }
                HStack{
                    Text("Path")
                    Spacer()
                    Text(task.files?.first?.path ?? "")
                }
            }
            Section("Files"){
                ForEach(task.files!) { file in
                    Text(file.path)
                }
            }
        }
        .onAppear(perform: loadData)
        .navigationTitle("Task")
    }
    func loadData() {
        Task {
            task = try! await rpc.tellStatus(gid: task.gid)
        }
    }
}

struct AddTaskView: View {
    @Binding var isPresented: Bool
    @ObservedObject var rpc: Aria2API
    @State private var url = ""
    
    var body: some View {
        NavigationView {
            Form {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $url)
                        .padding(.horizontal, -4)
                        .frame(minHeight: 200)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Add New Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Confirm") {
                    if !url.isEmpty {
                        Task{
                            let urls = url.split(separator: "\n")
                            try! await rpc.addUri(urls: urls.map({ x in
                                return String(x)
                            }))
                            isPresented = false
                        }
                    }
                    
                }
            )
        }
    }
}

struct ProgressBar: View {
    var value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .opacity(0.3)
                Rectangle()
                    .frame(width: max(0, min(geometry.size.width * CGFloat(value), geometry.size.width)))
                    .foregroundColor(.blue)
            }
        }
        .frame(height: 3)
    }
}
