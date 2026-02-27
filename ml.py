import pandas as pd 
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
data=pd.read_excel(r"C:\Users\Ravindra Srikar\Downloads\student_pass_fail_dataset.xlsx")
x=data[["StudyHours","Attendance","PreviousScore"]]
y=data["Pass"]
model=LogisticRegression()
#splitting data into training and testing and 75% training data and 25% of test data
x_train,x_test,y_train,y_test=train_test_split(
    x,y,test_size=0.25,random_state=42
)
# giving training data to model to train the model
model.fit(x_train,y_train)

# predicting the x test value
abc=model.predict(x_test)

#checking the accuracy score by giving the x and y test values
ac=accuracy_score(y_test,abc)

newData=[[5,55,72]] # new data
predictedValue=model.predict(newData) # predicting the result by probiding new data to already trained model on train 75% data of datset

prob=model.predict_proba(newData)[0] #probability checking

fail_per=prob[0] * 100
pass_per=prob[1] * 100
print(prob,"probability")
print(predictedValue,"prValue")
print(round(fail_per,2),"failper")
print(round(pass_per,2),"passper")
# print(ac)