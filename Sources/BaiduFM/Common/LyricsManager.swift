//
//  LyricsManager.swift
//  BaiduFM
//
//  智能歌词管理器 - 支持LRC格式解析、时间同步和自动滚动
//  提供流畅的歌词显示体验
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - 歌词行数据模型
struct LyricLine {
    let time: TimeInterval      // 歌词显示时间（秒）
    let text: String           // 歌词文本
    let duration: TimeInterval // 该行歌词持续时间
}

// MARK: - 歌词解析错误类型
enum LyricsError: Error, LocalizedError {
    case invalidFormat
    case noLyrics
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "歌词格式无效"
        case .noLyrics:
            return "暂无歌词"
        case .networkError:
            return "歌词加载失败"
        }
    }
}

// MARK: - 歌词管理器
class LyricsManager {
    
    // MARK: - 单例
    static let shared = LyricsManager()
    
    // MARK: - 私有属性
    private let disposeBag = DisposeBag()
    private var currentLyrics: [LyricLine] = []
    
    // MARK: - 公共响应式属性
    let lyricsLines = BehaviorRelay<[LyricLine]>(value: [])
    let currentLyricIndex = BehaviorRelay<Int>(value: -1)
    let isLyricsAvailable = BehaviorRelay<Bool>(value: false)
    
    // MARK: - 初始化
    private init() {
        setupBindings()
    }
    
    // MARK: - 设置数据绑定
    private func setupBindings() {
        // 监听AudioManager的播放时间变化，自动更新当前歌词行
        AudioManager.shared.currentTime
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] currentTime in
                self?.updateCurrentLyricIndex(for: currentTime)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - 加载歌词
    func loadLyrics(from urlString: String) -> Observable<Void> {
        return NetworkManager.shared.getLyrics(url: urlString)
            .flatMap { [weak self] lyricsText -> Observable<Void> in
                guard let self = self else { return Observable.just(()) }
                
                do {
                    let parsedLyrics = try self.parseLRC(lyricsText)
                    self.currentLyrics = parsedLyrics
                    self.lyricsLines.accept(parsedLyrics)
                    self.isLyricsAvailable.accept(!parsedLyrics.isEmpty)
                    return Observable.just(())
                } catch {
                    self.clearLyrics()
                    return Observable.error(error)
                }
            }
            .catch { [weak self] error in
                self?.clearLyrics()
                return Observable.just(())
            }
    }
    
    // MARK: - LRC格式歌词解析
    private func parseLRC(_ lyricsText: String) throws -> [LyricLine] {
        let lines = lyricsText.components(separatedBy: .newlines)
        var lyricLines: [LyricLine] = []
        
        // LRC时间标签正则表达式: [mm:ss.xx]
        let timePattern = "\\[(\\d{2}):(\\d{2})\\.(\\d{2})\\](.+)"
        let regex = try NSRegularExpression(pattern: timePattern, options: [])
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }
            
            let range = NSRange(location: 0, length: trimmedLine.utf16.count)
            
            if let match = regex.firstMatch(in: trimmedLine, options: [], range: range) {
                // 提取时间和歌词文本
                let minutesRange = Range(match.range(at: 1), in: trimmedLine)!
                let secondsRange = Range(match.range(at: 2), in: trimmedLine)!
                let millisecondsRange = Range(match.range(at: 3), in: trimmedLine)!
                let textRange = Range(match.range(at: 4), in: trimmedLine)!
                
                let minutes = Int(trimmedLine[minutesRange]) ?? 0
                let seconds = Int(trimmedLine[secondsRange]) ?? 0
                let milliseconds = Int(trimmedLine[millisecondsRange]) ?? 0
                let text = String(trimmedLine[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 计算总时间（秒）
                let totalTime = TimeInterval(minutes * 60 + seconds) + TimeInterval(milliseconds) / 100.0
                
                // 过滤空白歌词行
                if !text.isEmpty && text != "..." {
                    let lyricLine = LyricLine(time: totalTime, text: text, duration: 0)
                    lyricLines.append(lyricLine)
                }
            }
        }
        
        // 按时间排序
        lyricLines.sort { $0.time < $1.time }
        
        // 计算每行歌词的持续时间
        for i in 0..<lyricLines.count {
            if i < lyricLines.count - 1 {
                lyricLines[i] = LyricLine(
                    time: lyricLines[i].time,
                    text: lyricLines[i].text,
                    duration: lyricLines[i + 1].time - lyricLines[i].time
                )
            } else {
                // 最后一行歌词默认持续3秒
                lyricLines[i] = LyricLine(
                    time: lyricLines[i].time,
                    text: lyricLines[i].text,
                    duration: 3.0
                )
            }
        }
        
        return lyricLines
    }
    
    // MARK: - 更新当前歌词行索引
    private func updateCurrentLyricIndex(for currentTime: TimeInterval) {
        guard !currentLyrics.isEmpty else {
            currentLyricIndex.accept(-1)
            return
        }
        
        // 二分查找当前应该显示的歌词行
        var left = 0
        var right = currentLyrics.count - 1
        var resultIndex = -1
        
        while left <= right {
            let mid = (left + right) / 2
            let lyricTime = currentLyrics[mid].time
            
            if lyricTime <= currentTime {
                resultIndex = mid
                left = mid + 1
            } else {
                right = mid - 1
            }
        }
        
        // 检查是否在有效时间范围内
        if resultIndex >= 0 {
            let lyric = currentLyrics[resultIndex]
            if currentTime <= lyric.time + lyric.duration {
                currentLyricIndex.accept(resultIndex)
            } else {
                currentLyricIndex.accept(-1)
            }
        } else {
            currentLyricIndex.accept(-1)
        }
    }
    
    // MARK: - 获取当前显示的歌词
    var currentLyricText: Observable<String> {
        return Observable.combineLatest(
            lyricsLines,
            currentLyricIndex
        )
        .map { (lyrics, index) -> String in
            guard index >= 0 && index < lyrics.count else {
                return "♪ 暂无歌词 ♪"
            }
            return lyrics[index].text
        }
    }
    
    // MARK: - 获取歌词上下文（当前行+前后几行）
    func getLyricsContext(around index: Int, contextLines: Int = 2) -> [LyricLine] {
        guard !currentLyrics.isEmpty else { return [] }
        
        let startIndex = max(0, index - contextLines)
        let endIndex = min(currentLyrics.count - 1, index + contextLines)
        
        return Array(currentLyrics[startIndex...endIndex])
    }
    
    // MARK: - 清空歌词
    func clearLyrics() {
        currentLyrics.removeAll()
        lyricsLines.accept([])
        currentLyricIndex.accept(-1)
        isLyricsAvailable.accept(false)
    }
    
    // MARK: - 搜索歌词
    func searchLyrics(containing keyword: String) -> [Int] {
        return currentLyrics.enumerated().compactMap { index, lyric in
            lyric.text.localizedCaseInsensitiveContains(keyword) ? index : nil
        }
    }
    
    // MARK: - 获取歌词总时长
    var totalDuration: TimeInterval {
        guard let lastLyric = currentLyrics.last else { return 0 }
        return lastLyric.time + lastLyric.duration
    }
    
    // MARK: - 获取歌词进度百分比
    func getLyricsProgress(for currentTime: TimeInterval) -> Float {
        let total = totalDuration
        return total > 0 ? Float(currentTime / total) : 0.0
    }
}

// MARK: - 歌词显示辅助方法
extension LyricsManager {
    
    /// 格式化时间显示
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    /// 获取歌词预览文本（前几行）
    func getPreviewText(lines: Int = 3) -> String {
        let previewLyrics = Array(currentLyrics.prefix(lines))
        return previewLyrics.map { $0.text }.joined(separator: "\n")
    }
    
    /// 检查歌词质量（是否包含有意义的内容）
    var lyricsQuality: LyricsQuality {
        if currentLyrics.isEmpty {
            return .none
        } else if currentLyrics.count < 5 {
            return .poor
        } else if currentLyrics.allSatisfy({ $0.text.count < 10 }) {
            return .basic
        } else {
            return .good
        }
    }
}

// MARK: - 歌词质量枚举
enum LyricsQuality {
    case none    // 无歌词
    case poor    // 歌词较少
    case basic   // 基本歌词
    case good    // 高质量歌词
    
    var description: String {
        switch self {
        case .none: return "无歌词"
        case .poor: return "歌词较少"
        case .basic: return "基本歌词" 
        case .good: return "完整歌词"
        }
    }
} 