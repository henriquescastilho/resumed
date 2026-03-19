//
//  ExamPDFGenerator.swift
//  Resumed
//
//  Generates formatted exam PDFs with answer sheet
//

import UIKit

@MainActor
final class ExamPDFGenerator {
    static let shared = ExamPDFGenerator()
    private init() {}

    /// Generates a PDF for an exam and returns the file URL
    func generateExamPDF(exam: Exam) -> URL? {
        let pageWidth: CGFloat = 595.0  // A4
        let pageHeight: CGFloat = 842.0
        let margin: CGFloat = 50.0

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = pdfRenderer.pdfData { context in
            // Title / cover page
            context.beginPage()
            drawTitlePage(
                context: context,
                exam: exam,
                pageWidth: pageWidth,
                pageHeight: pageHeight,
                margin: margin
            )

            // Answer sheet page
            context.beginPage()
            drawAnswerSheet(
                context: context,
                exam: exam,
                pageWidth: pageWidth,
                pageHeight: pageHeight,
                margin: margin
            )
        }

        let safeName = exam.name.replacingOccurrences(of: "/", with: "-")
        let fileName = "RESUMED_\(safeName).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }

    // MARK: - Drawing Helpers

    private func drawTitlePage(
        context: UIGraphicsPDFRendererContext,
        exam: Exam,
        pageWidth: CGFloat,
        pageHeight: CGFloat,
        margin: CGFloat
    ) {
        let goldColor = UIColor(red: 0.83, green: 0.66, blue: 0.26, alpha: 1.0)
        let darkBg = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)

        // Background
        darkBg.setFill()
        context.cgContext.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        // "Resumed" brand
        let brandAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 36, weight: .bold),
            .foregroundColor: goldColor
        ]
        let brand = "Resumed™"
        let brandSize = brand.size(withAttributes: brandAttrs)
        brand.draw(
            at: CGPoint(x: (pageWidth - brandSize.width) / 2, y: pageHeight / 3),
            withAttributes: brandAttrs
        )

        // Exam name
        let examAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        let examName = exam.name
        let examSize = examName.size(withAttributes: examAttrs)
        examName.draw(
            at: CGPoint(x: (pageWidth - examSize.width) / 2, y: pageHeight / 3 + 54),
            withAttributes: examAttrs
        )

        // Question count + duration
        let metaAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.lightGray
        ]
        let meta = "\(exam.questionCount) questões  •  \(exam.formattedDuration)  •  Prova Objetiva"
        let metaSize = meta.size(withAttributes: metaAttrs)
        meta.draw(
            at: CGPoint(x: (pageWidth - metaSize.width) / 2, y: pageHeight / 3 + 90),
            withAttributes: metaAttrs
        )

        // Subject breakdown
        var yPos = pageHeight / 3 + 140
        let subjectAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.lightGray
        ]
        for subject in exam.subjects.prefix(6) {
            let text = "• \(subject.name): \(subject.questionCount) questões"
            text.draw(at: CGPoint(x: (pageWidth - 220) / 2, y: yPos), withAttributes: subjectAttrs)
            yPos += 20
        }

        // Footer
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        let footer = "Copyright © Resumed™ — Uso exclusivo para estudo"
        let footerSize = footer.size(withAttributes: footerAttrs)
        footer.draw(
            at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: pageHeight - margin),
            withAttributes: footerAttrs
        )
    }

    private func drawAnswerSheet(
        context: UIGraphicsPDFRendererContext,
        exam: Exam,
        pageWidth: CGFloat,
        pageHeight: CGFloat,
        margin: CGFloat
    ) {
        let goldColor = UIColor(red: 0.83, green: 0.66, blue: 0.26, alpha: 1.0)

        // Page title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        "FOLHA DE RESPOSTAS — \(exam.name)".draw(
            at: CGPoint(x: margin, y: margin),
            withAttributes: titleAttrs
        )

        // Subtitle
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        "Marque sua resposta e confira com o gabarito ao final.".draw(
            at: CGPoint(x: margin, y: margin + 26),
            withAttributes: subAttrs
        )

        // Name + date line
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.black
        ]
        "Nome: ___________________________________  Data: ___/___/______".draw(
            at: CGPoint(x: margin, y: margin + 52),
            withAttributes: nameAttrs
        )

        // Separator line
        UIColor.lightGray.setStroke()
        let sep = UIBezierPath()
        sep.move(to: CGPoint(x: margin, y: margin + 74))
        sep.addLine(to: CGPoint(x: pageWidth - margin, y: margin + 74))
        sep.lineWidth = 0.5
        sep.stroke()

        // Answer grid
        let columns = 5
        let cellWidth: CGFloat = (pageWidth - margin * 2) / CGFloat(columns)
        let cellHeight: CGFloat = 24
        let gridStartY = margin + 86

        let numAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        let letterAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        for i in 0..<exam.questionCount {
            let col = i % columns
            let row = i / columns
            let x = margin + CGFloat(col) * cellWidth
            let y = gridStartY + CGFloat(row) * cellHeight

            // Guard against going off the page
            if y + cellHeight > pageHeight - margin - 30 { break }

            // Question number label
            "\(i + 1).".draw(at: CGPoint(x: x + 2, y: y + 5), withAttributes: numAttrs)

            // Option circles A B C D
            for (j, letter) in ["A", "B", "C", "D"].enumerated() {
                let circleX = x + 26 + CGFloat(j) * 20
                let circleRect = CGRect(x: circleX, y: y + 4, width: 14, height: 14)
                UIColor.lightGray.setStroke()
                let circle = UIBezierPath(ovalIn: circleRect)
                circle.lineWidth = 0.8
                circle.stroke()
                letter.draw(at: CGPoint(x: circleX + 3.5, y: y + 4.5), withAttributes: letterAttrs)
            }
        }

        // Footer
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        "Resumed™ — Folha de Respostas".draw(
            at: CGPoint(x: margin, y: pageHeight - margin),
            withAttributes: footerAttrs
        )
        _ = goldColor // used for branding context; retained for future use
    }
}
