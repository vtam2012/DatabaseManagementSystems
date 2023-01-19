# Create folder structure
# CS5200 Assignment / Build Document Database

if (dir.exists("docDB"))
{
  unlink("docDB", recursive = T)
}

dir.create("docDB")
dir.create("docDB/reports")
dir.create("docDB/reports/2021")
dir.create("docDB/reports/2021/Q1")
dir.create("docDB/reports/2021/Q2")
dir.create("docDB/reports/2021/Q3")
dir.create("docDB/reports/2021/Q4")
dir.create("docDB/reports/2021/Q1/AvalonLLC")
dir.create("docDB/reports/2021/Q1/Medix")
dir.create("docDB/reports/2021/Q1/CarrePoint")
dir.create("docDB/reports/2021/Q2/AvalonLLC")
dir.create("docDB/reports/2021/Q2/Medix")
dir.create("docDB/reports/2021/Q2/CarrePoint")
