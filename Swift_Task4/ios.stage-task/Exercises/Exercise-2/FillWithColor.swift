import Foundation

final class FillWithColor {
    var template = 0 //создаем свойство для записи первого элемента, чтобы потом сравнивать остальные
    var imagePixels = [[Int]]() //создаем свойство которое будем перекрашивать, чтобы легко было обращаться
    
    func fillWithColor(_ image: [[Int]], _ row: Int, _ column: Int, _ newColor: Int) -> [[Int]] {
        //делаем все проверки по условию задачи
        guard row >= 0 && row < image.count &&
                image.count >= 1 && image.count <= 50 &&
                column >= 0 && column < image[row].count &&
                image[row].count >= 1 && image[row].count <= 50 &&
                image[row][column] >= 0 && image[row][column] < 65536 &&
                newColor >= 0 && newColor < 65536
        else {return image}
        
        
        imagePixels = image //сохраняем картинку в свойство класса, чтобы работать из любого места
        template = image[row][column] //сохраняем первое значение, чтобы сравнивать остальные
        
        paintPixel(row, column, newColor) //запускаем метод покраски
        
        return imagePixels
    }
    
    private func paintPixel(_ i: Int, _ j: Int, _ newColor: Int){
        //проверяем чтобы при рекурсии не вышли за рамки матрицы + чтобы значение было равно начальному и могли покрасить
        guard
            i >= 0 && i < imagePixels.count &&
            j >= 0 && j < imagePixels[i].count &&
            imagePixels[i][j] == template &&
            imagePixels[i][j] != newColor
        else {return}
        
        imagePixels[i][j] = newColor //если все хорошо красим
        
        //рекурсивно для каждого элемента делаем обход
        paintPixel(i, j + 1, newColor) //право
        paintPixel(i + 1, j, newColor) //низ
        paintPixel(i, j - 1, newColor) //лево
        paintPixel(i - 1, j, newColor) //верх
    }
}
